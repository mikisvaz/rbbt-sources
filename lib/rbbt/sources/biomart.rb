require 'rbbt-util'
require 'rbbt/util/log'

# This module interacts with BioMart. It performs queries to BioMart and
# synthesises a hash with the results. Note that this module connects to the
# online BioMart WS using the Open in 'rbbt/util/open' module which offers
# caching by default. To obtain up to date results you may need to clear the
# cache from previous queries.
module BioMart
  
  class BioMart::QueryError < StandardError; end

  BIOMART_URL = 'http://biomart.org/biomart/martservice?query='

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
    @archive_url = BIOMART_URL.sub(/http:\/\/biomart\./, 'http://' + date + '.archive.ensembl.')
    Log.debug "Using Archive URL #{ @archive_url }"
  end

  def self.unset_archive
    Log.debug "Restoring current version URL #{BIOMART_URL}"
    @archive_url = nil
  end

  def self.get(database, main, attrs = nil, filters = nil, data = nil, open_options = {})
    repeats = true
    attrs   ||= []
    filters ||= ["with_#{main}"]
    data    ||= {}
  
    query = @@biomart_query_xml.dup
    query.sub!(/<!--DATABASE-->/,database)
    query.sub!(/<!--FILTERS-->/, filters.collect{|name, v| v.nil? ? "<Filter name = \"#{ name }\" excluded = \"0\"/>" : "<Filter name = \"#{ name }\" value = \"#{v * ","}\"/>" }.join("\n") )
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

    response.each_line{|l|
      parts = l.chomp.split(/\t/)
      main = parts.shift
      next if main.nil? || main.empty?

      data[main] ||= {}
      attrs.each{|name|
        value = parts.shift
        data[main][name] ||= []
        next if value.nil? or value.empty?
        if data[main][name].empty?
          data[main][name] = [value]
        else
          data[main][name] << value unless repeats or data[main][name].include?(value)
        end
      }
    }

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
    open_options = Misc.add_defaults open_options, :nocache => false
    attrs   ||= []
    data    ||= {}
    
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
      Log.low "Chunk #{ i }: [#{chunk * ", "}]"
      data = get(database, main, chunk, filters, data, open_options)
    }

    data
  end

  def self.tsv(database, main, attrs = nil, filters = nil, data = nil, open_options = {})
    codes = attrs.collect{|attr| attr[1]}
    data = query(database, main.last, codes, filters, data, open_options)
    tsv = TSV.new({})

    data.each do |key, info|
      tsv[key] = info.values_at(*codes)
    end

    tsv.key_field = main.first
    tsv.fields    = attrs.collect{|attr| attr.first} 
    tsv
  end
end

