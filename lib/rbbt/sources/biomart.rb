require 'rbbt-util'

# This module interacts with BioMart. It performs queries to BioMart and
# synthesises a hash with the results. Note that this module connects to the
# online BioMart WS using the Open in 'rbbt/util/open' module which offers
# caching by default. To obtain up to date results you may need to clear the
# cache from previous queries.
module BioMart
  
  class BioMart::QueryError < StandardError; end
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

   


  def self.get(database, main, attrs = nil, filters = nil, data = nil, open_options = {})
    attrs   ||= []
    filters ||= ["with_#{main}"]
    data    ||= {}
  
    query = @@biomart_query_xml.dup
    query.sub!(/<!--DATABASE-->/,database)
    query.sub!(/<!--FILTERS-->/, filters.collect{|name| "<Filter name = \"#{ name }\" excluded = \"0\"/>"}.join("\n") )
    query.sub!(/<!--MAIN-->/,"<Attribute name = \"#{main}\" />")
    query.sub!(/<!--ATTRIBUTES-->/, attrs.collect{|name| "<Attribute name = \"#{ name }\"/>"}.join("\n") )

    response = Open.read('http://www.biomart.org/biomart/martservice?query=' + query.gsub(/\n/,' '), open_options)
    if response =~ /Query ERROR:/
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
        if data[main][name]
          data[main][name] = [value]
        else
          data[main][name] << value unless data[main][name].include? value
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
    attrs   ||= []
    data    ||= {}
    
    chunks = []
    chunk = []
    attrs.each{|a|
      chunk << a
      if chunk.length == 2
        chunks << chunk
        chunk = []
      end
    }

    chunks << chunk if chunk.any?

    chunks.each{|chunk|
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

