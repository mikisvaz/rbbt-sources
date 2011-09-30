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

  BIOMART_URL = 'http://biomart.org/biomart/martservice?query='

  MISSING_IN_ARCHIVE = Rbbt.etc.biomart.missing_in_archive.exists? ? Rbbt.etc.biomart.missing_in_archive.yaml : {}

  private

  @@biomart_query_xml = <<-EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Query>        
<Query  virtualSchemaName = "default" formatter = "TSV" header = "0" uniqueRows = "1" count = "" datasetConfigVersion = "0.6" >
<Dataset name = "<!--DATABASE-->" interface = "default" >
<!--FILTERS-->
<!--MAIN-->           
<!--ATTRIBUTES-->     
</Dataset>
</Query>
  EOT
   
  def self.set_archive(date)
    if defined? Rbbt and Rbbt.etc.allowed_biomart_archives.exists?
      raise "Biomart archive #{ date } is not allowed in this installation" unless Rbbt.etc.allowed_biomart_archives.read.split("\n").include? date
    end
    @archive = date
    @archive_url = BIOMART_URL.sub(/http:\/\/biomart\./, 'http://' + date + '.archive.ensembl.')
    Log.debug "Using Archive URL #{ @archive_url }"
  end

  def self.unset_archive
    Log.debug "Restoring current version URL #{BIOMART_URL}"
    @archive = nil
    @archive_url = nil
  end

  def self.get(database, main, attrs = nil, filters = nil, data = nil, open_options = {})
    repeats = true
    attrs   ||= []
    filters ||= ["with_#{main}"]

    query = @@biomart_query_xml.dup
    query.sub!(/<!--DATABASE-->/,database)
    query.sub!(/<!--FILTERS-->/, filters.collect{|name, v| v.nil? ? "<Filter name = \"#{ name }\" excluded = \"0\"/>" : "<Filter name = \"#{ name }\" value = \"#{Array === v ? v * "," : v}\"/>" }.join("\n") )
    query.sub!(/<!--MAIN-->/,"<Attribute name = \"#{main}\" />")
    query.sub!(/<!--ATTRIBUTES-->/, attrs.collect{|name| "<Attribute name = \"#{ name }\"/>"}.join("\n") )

    if @archive_url
      response = Open.read(@archive_url + query.gsub(/\n/,' '), open_options)
    else
      response = Open.read(BIOMART_URL + query.gsub(/\n/,' '), open_options)
    end

    if response.empty? or response =~ /Query ERROR:/
      raise BioMart::QueryError, response
    end

    result_file = TmpFile.tmp_file
    Open.write(result_file, response)

    new_datafile = TmpFile.tmp_file
    if data.nil?
      TSV.merge_row_fields Open.open(result_file), new_datafile
      data = new_datafile
    else
      TSV.merge_different_fields data, result_file, new_datafile
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
    open_options = Misc.add_defaults open_options, :nocache => false, :filename => nil, :field_names => nil
    filename, field_names = Misc.process_options open_options, :filename, :field_names
    attrs   ||= []
      
    open_options = Misc.add_defaults open_options, :keep_empty => false, :merge => true

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

    Log.low "Chunks: #{chunks.length}"
    chunks.each_with_index{|chunk,i|
      Log.low "Chunk #{ i + 1 } / #{chunks.length}: [#{chunk * ", "}]"
      data = get(database, main, chunk, filters, data, open_options)
    }

    open_options[:filename] ||= "BioMart[#{main}+#{attrs.length}]"
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
    if @archive_url 
      attrs = attrs.reject{|attr| (MISSING_IN_ARCHIVE[@archive] || []).include? attr[1]}
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

