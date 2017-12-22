require 'rbbt-util'
require 'rbbt/resource'

module PRO
  extend Resource
  self.subdir = 'share/databases/PRO'

  def self.organism(org="Hsa")
    require 'rbbt/sources/organism'
    Organism.default_code(org)
  end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib

  PRO.claim PRO.identifiers, :proc do 
    url = "ftp://ftp.pir.georgetown.edu/databases/ontology/pro_obo/PRO_mappings/uniprotmapping.txt"

    dumper = TSV::Dumper.new :key_field => "PRO ID", :fields => ["UniProt/SwissProt Accession"], :type => :double, :namespace => PRO.organism
    dumper.init
    TSV.traverse Open.open(url), :type => :array, :into => dumper, :bar => true do |line|
      pro, uni = line.split("\t")
      [pro, [uni.split(":").last]]
    end
    TSV.collapse_stream dumper
  end

  PRO.claim PRO.uniprot_equivalences, :proc do
    
    dumper = TSV::Dumper.new :key_field => "UniProt/SwissProt Accession", :fields => ["UniProt/SwissProt Accession"], :type => :flat, :namespace => PRO.organism
    dumper.init
    TSV.traverse PRO.identifiers, :into => dumper,  :bar => true do |pro,values|
      res = []
      res.extend MultipleResult
      unis = values.flatten

      unis.flatten.each do |uni|
        res << [uni,unis]
      end

      res
    end
  end
end

iif PRO.identifiers.produce(true).find if __FILE__ == $0
iif PRO.uniprot_equivalences.produce(true).find if __FILE__ == $0

