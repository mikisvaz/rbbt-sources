require 'rbbt'
require 'rbbt/resource'
require 'rbbt/persist/tsv'

# This module holds helper methods to deal with the Gene Ontology files. Right
# now all it does is provide a translation form id to the actual names.
module GO

  Rbbt.claim Rbbt.share.databases.GO.gene_ontology, :url, 'ftp://ftp.geneontology.org/pub/go/ontology/gene_ontology.obo'
  Rbbt.claim Rbbt.share.databases.GO.gslim_generic, :url, 'http://www.geneontology.org/GO_slims/goslim_generic.obo'

  MULTIPLE_VALUE_FIELDS = %w(is_a)
  TSV_GENE_ONTOLOGY = File.join(Persist.cachedir, 'gene_ontology')

  # This method needs to be called before any translations can be made, it is
  # called automatically the first time the id2name method is called. It loads
  # the gene_ontology.obo file and extracts all the fields, although right now,
  # only the name field is used.
  def self.init
    Persist.persist_tsv(nil, 'gene_ontology', {}, :persist => true) do |info|
      info.serializer = :marshal if info.respond_to? :serializer and info.serializer == :type
      Rbbt.share.databases.GO.gene_ontology.read.split(/\[Term\]/).each{|term| 
        term_info = {}

        term.split(/\n/). select{|l| l =~ /:/}.each{|l| 
          key, value = l.chomp.match(/(.*?):(.*)/).values_at(1,2)
          if MULTIPLE_VALUE_FIELDS.include? key.strip
            term_info[key.strip] ||= []
            term_info[key.strip] << value.strip
          else
            term_info[key.strip] = value.strip
          end
        }

        next if term_info["id"].nil?
        info[term_info["id"]] = term_info
      }

      info
    end
  end

  def self.info
    @info ||= self.init
  end

  def self.goterms
    info.keys
  end

  def self.id2name(id)
    if id.kind_of? Array
      info.values_at(*id).collect{|i| i['name'] if i}
    else
      return nil if info[id].nil?
      info[id]['name']
    end
  end

  def self.id2ancestors(id)
    if id.kind_of? Array
      info.values_at(*id).
        select{|i| ! i['is_a'].nil?}.
        collect{|i| i['is_a'].collect{|id| 
        id.match(/(GO:\d+)/)[1] if id.match(/(GO:\d+)/)
      }.compact
      }
    else
      return [] if id.nil? or info[id].nil? or info[id]['is_a'].nil?
      info[id]['is_a'].
        collect{|id| 
        id.match(/(GO:\d+)/)[1] if id.match(/(GO:\d+)/)
      }.compact
    end
  end

  def self.id2namespace(id)
    self.init unless info
    if id.kind_of? Array
      info.values_at(*id).collect{|i| i['namespace'] if i}
    else
      return nil if info[id].nil?
      info[id]['namespace']
    end
  end
end
