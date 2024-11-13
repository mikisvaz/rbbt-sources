require 'rbbt'
require 'rbbt/tsv'
require 'rbbt/tsv/attach'
require 'rbbt/util/log'
require 'cgi'

# This module interacts with BioMart. It performs queries to BioMart and
# synthesises a hash with the results. Note that this module connects to the
# online BioMart WS using the Open in 'rbbt/util/open' module which offers
# caching by default. To obtain up to date results you may need to clear the
# cache from previous queries.
module BioMart
  
  class BioMart::QueryError < StandardError; end

  BIOMART_URL = 'ensembl.org/biomart/martservice'

  MISSING_IN_ARCHIVE = Rbbt.etc.biomart.missing_in_archive.exists? ? Rbbt.etc.biomart.missing_in_archive.find.yaml : {}

  private

  @@biomart_query_xml = <<-EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Query>
<Query completionStamp="1" virtualSchemaName = "<!--VIRTUALSCHEMANAME-->" formatter = "TSV" header = "0" uniqueRows = "1" count = "" datasetConfigVersion = "0.6" >
<Dataset name = "<!--DATABASE-->" interface = "default" >
<!--FILTERS-->
<!--MAIN-->
<!--ATTRIBUTES-->
</Dataset>
</Query>
  EOT
   
  def self.set_archive(date)
    if defined? Rbbt and Rbbt.etc.allowed_biomart_archives.exists?
      raise "Biomart archive #{ date } is not allowed in this installation" unless Rbbt.etc.allowed_biomart_archives.find.read.split("\n").include? date
    end
    Thread.current['archive'] = date
  end

  def self.unset_archive
    Thread.current['archive'] = nil
  end

  def self.with_archive(data)
    begin
      set_archive(data)
      yield
    ensure
      unset_archive
    end
  end

  def self.final_url(query, archive = nil, ensembl_domain = nil)
    url_domain = if archive.nil?
      if ensembl_domain.nil?
        'www'
      else
        ensembl_domain
      end
    elsif ensembl_domain
      [archive, ensembl_domain] * "-"
    else
      [archive, 'archive'] * "."
    end
    "http://" + url_domain + "." + BIOMART_URL + "?query=#{query}"
  end

  def self.get(database, main, attrs = nil, filters = nil, data = nil, open_options = {})
    open_options = Misc.add_defaults open_options, :wget_options => {"--read-timeout=" => 9000, "--tries=" => 1}
    repeats = true
    attrs   ||= []
    filters ||= ["with_#{main}"]

    if chunk_filter = open_options.delete(:chunk_filter)
      filter, values = chunk_filter
      merged_file = TmpFile.tmp_file
      f = File.open(merged_file, 'w')
      values.each do |value|
        data = get(database, main, attrs, filters + [[filter, value]], data, open_options)
        f.write Open.read(data)
      end
      f.close
      return merged_file
    end

    query = @@biomart_query_xml.dup
    query.sub!(/<!--DATABASE-->/,database)
    if Thread.current["ensembl_domain"]
      query.sub!(/<!--VIRTUALSCHEMANAME-->/, Thread.current["ensembl_domain"] + "_mart")
    else
      query.sub!(/<!--VIRTUALSCHEMANAME-->/,'default')
    end
    query.sub!(/<!--FILTERS-->/, filters.collect{|name, v| v.nil? ? "<Filter name = \"#{ name }\" excluded = \"0\"/>" : "<Filter name = \"#{ name }\" value = \"#{Array === v ? v * "," : v}\"/>" }.join("\n") )
    query.sub!(/<!--MAIN-->/,"<Attribute name = \"#{main}\" />")
    query.sub!(/<!--ATTRIBUTES-->/, attrs.collect{|name| "<Attribute name = \"#{ name }\"/>"}.join("\n") )

    url = final_url(query,  Thread.current["archive"], Thread.current["ensembl_domain"])


    begin
      response = Open.read(url, open_options.dup)
    rescue
      Open.remove_from_cache url, open_options
      raise $!
    end

    if response.empty? or response =~ /Query ERROR:/ 
      Open.remove_from_cache url, open_options
      raise BioMart::QueryError, response
    end

    if not response =~ /\[success\]$/sm
      Open.remove_from_cache url, open_options
      raise BioMart::QueryError, "Uncomplete result"
    end

    response.sub!(/\n\[success\]$/sm,'')

    result_file = TmpFile.tmp_file
    Open.write(result_file, response)

    new_datafile = TmpFile.tmp_file
    if data.nil?
      TSV.merge_row_fields Open.open(result_file), new_datafile
      data = new_datafile
    else
      TSV.merge_different_fields Open.open(data), Open.open(result_file), new_datafile, one2one: false, sort: true
      FileUtils.rm data
      data = new_datafile
    end
    FileUtils.rm result_file

    data
  end

  public

  # This method performs a query in biomart for a datasets and a given set of
  # attributes, there must be a main attribute that will be used as the key in
  # the result hash, optionally there may be a list of additional attributes
  # and filters. The data parameter at the end is used internally to
  # incrementally building the result, due to a limitation of the BioMart WS
  # that only allows 3 external arguments, users normally should leave it
  # unspecified or nil. The result is a hash, where the keys are the different
  # values for the main attribute, and the value is a hash with every other
  # attribute as key, and as value and array with all possible values (Note
  # that for a given value of the main attribute, there may be more than one
  # value for another attribute). If filters is left a nil it adds a filter to
  # the BioMart query to remove results with the main attribute empty, this may
  # cause an error if the BioMart WS does not allow filtering with that
  # attribute.
  def self.query(database, main, attrs = nil, filters = nil, data = nil, open_options = {})
    IndiferentHash.setup(open_options)
    open_options = Misc.add_defaults open_options, :nocache => false, :filename => nil, :field_names => nil, :by_chr => false
    filename, field_names, by_chr = Misc.process_options open_options, :filename, :field_names, :by_chr
    attrs   ||= []
    open_options = Misc.add_defaults open_options, :keep_empty => false, :merge => true

    IndiferentHash.setup(open_options)

    Log.low "BioMart query: '#{main}' [#{(attrs || []) * ', '}] [#{(filters || []) * ', '}] #{open_options.inspect}"

    max_items = 2
    chunks = []
    chunk = []
    attrs.each{|a|
      chunk << a
      if chunk.length == max_items
        chunks << chunk
        chunk = []
      end
    }

    chunks << chunk if chunk.any?

    chunks << [] if chunks.empty?

    Log.low "Chunks: #{chunks.length}"
    if chunks.any?
      chunks.each_with_index{|chunk,i|
        Log.low "Chunk #{ i + 1 } / #{chunks.length}: [#{chunk * ", "}]"
        data = get(database, main, chunk, filters, data, open_options.dup)
      }
    else
      data = get(database, main, [], filters, data, open_options.dup)
    end

    open_options[:filename] = "BioMart[#{main}+#{attrs.length}]"

    if filename.nil?
      results = TSV.open data, open_options
      results.key_field = main
      results.fields = attrs
      results
    else
      Open.write(filename) do |f|
        f.puts "#: " << Misc.hash2string(TSV::ENTRIES.collect{|key| [key, open_options[key]]})
        if field_names.nil?
          f.puts "#" << [main, attrs].flatten * "\t"
        else
          f.puts "#" << field_names * "\t"
        end
        f.write Open.read(data)
      end
      FileUtils.rm data
      filename
    end
  end

  def self.tsv(database, main, attrs = nil, filters = nil, data = nil, open_options = {})
    attrs ||= []

    current_archive = Thread.current['archive'] 
    missing = MISSING_IN_ARCHIVE['all'] || []
    missing += MISSING_IN_ARCHIVE[current_archive] || [] if current_archive

    MISSING_IN_ARCHIVE.each do |k,v|
      if k =~ /^<(.*)/ 
        t = $1.strip
        missing+=v if Organism.compare_archives(current_archive, t) == -1
      elsif k=~ /^>(.*)/ 
        t = $1.strip
        missing+=v if Organism.compare_archives(current_archive, t) == 1
      end
    end
    attrs = attrs.uniq.reject{|attr| missing.include? attr[1]}
    changes = {}
    missing.select{|m| m.include? "~" }.each do |str|
      orig,_sep, new = str.partition "~"
      if orig.include?(":")
        target_db, _sep, orig = orig.partition(":")
        if target_db[0] == "-"
          next if database == target_db[1..-1]
        else
          next unless database == target_db
        end
        changes[orig] = new
      else
        changes[orig] = new
      end
    end
    changed = true
    while changed
      new_attrs = attrs.collect{|n,k| [n, changes[k] || k] }
      changed = new_attrs != attrs
      attrs = new_attrs
    end


    codes = attrs.collect{|attr| attr[1]}
    if open_options[:filename].nil?
      tsv = query(database, main.last, codes, filters, data, open_options)
      tsv.key_field = main.first
      tsv.fields    = attrs.collect{|attr| attr.first} 
      tsv
    else
      query(database, main.last, codes, filters, data, open_options.merge(:field_names => [main.first, attrs.collect{|attr| attr.first}].flatten))
    end
  end
end

