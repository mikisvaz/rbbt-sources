require 'rbbt-util'
require 'rbbt/resource'

module CORUM
  extend Resource
  self.subdir = 'share/databases/CORUM'

  def self.organism(org="Hsa")
    Organism.default_code(org)
  end

  CORUM.claim CORUM.complex_names, :proc do 
    url = "http://mips.helmholtz-muenchen.de/genre/proj/corum/allComplexes.csv"
    tsv = TSV.open(url, :header_hash => "", :sep => ';', :sep2 => ',', :fix => Proc.new{|l| "CORUM:" + l.gsub('"','')})
    tsv.namespace = organism
    tsv.fields = tsv.fields.collect{|f| f.gsub('"','')}
    tsv.key_field = "CORUM Complex ID"
    tsv.slice("Complex name").to_single
  end

  CORUM.claim CORUM.complexes, :proc do 
    url = "http://mips.helmholtz-muenchen.de/genre/proj/corum/allComplexes.csv"
    tsv = TSV.open(url, :header_hash => "", :sep => ';', :sep2 => ',', :fix => Proc.new{|l| "CORUM:" + l.gsub('"','')})
    tsv.namespace = organism
    tsv.fields = tsv.fields.collect{|f| f.gsub('"','')}
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
      @genes ||= CORUM.complexes.tsv(:persist => true, :fields => ["subunits (UniProt IDs)"], :type => :flat).values_at *self
    end
  end
end
