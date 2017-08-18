require 'rbbt-util'
require 'rbbt/resource'
require 'rbbt/sources/organism'

module CORUM
  extend Resource
  self.subdir = 'share/databases/CORUM'

  def self.organism(org="Hsa")
    Organism.default_code(org)
  end

  CORUM.claim CORUM.complex_names, :proc do 
    url = "http://mips.helmholtz-muenchen.de/corum/download/allComplexes.txt"
    tsv = TSV.open(url, :header_hash => "", :sep2 => ';', :fix => Proc.new{|l| "CORUM:" + l.delete('"')})
    tsv.namespace = organism
    tsv.fields = tsv.fields.collect{|f| f.delete('"')}
    tsv.key_field = "CORUM Complex ID"
    tsv = tsv.slice("ComplexName").to_single
    tsv.fields = ["Complex name"]
    tsv
  end

  CORUM.claim CORUM.complexes, :proc do 
    url = "http://mips.helmholtz-muenchen.de/corum/download/allComplexes.txt"
    tsv = TSV.open(url, :header_hash => "", :sep2 => ';', :fix => Proc.new{|l| "CORUM:" + l.delete('"')})
    tsv.namespace = organism
    tsv.fields = tsv.fields.collect{|f| f.delete('"')}.collect{|f|
      case f
      when "subunits (UniProt IDs)"
        "UniProt/SwissProt Accession"
      when "subunits (Entrez IDs)"
        "Entrez Gene ID"
      else
        f
      end
    }
    tsv.key_field = "CORUM Complex ID"
    tsv.identifiers = CORUM.complex_names.produce.find
    tsv
  end

end

if defined? Entity
  module CORUMComplex
    extend Entity

    self.annotation :format
    self.annotation :organism
    self.add_identifiers CORUM.complex_names, "CORUM Complex ID", "Complex name"

    property :genes => :array2single do
      @genes ||= CORUM.complexes.tsv(:persist => true, :fields => ["UniProt/SwissProt Accession"], :type => :flat).values_at *self
    end
  end
end
