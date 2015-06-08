require 'rbbt-util'
require 'rbbt/resource'

module CORUM
  extend Resource
  self.subdir = 'share/databases/CORUM'

  def self.organism(org="Hsa")
    Organism.default_code(org)
  end

  CORUM.claim CORUM.complexes, :proc do 
    url = "http://mips.helmholtz-muenchen.de/genre/proj/corum/allComplexes.csv"
    tsv = TSV.open(url, :header_hash => "", :sep => ';', :sep2 => ',', :fix => Proc.new{|l| "CORUM:" + l.gsub('"','')})
    tsv.fields = tsv.fields.collect{|f| f.gsub('"','')}
    tsv.key_field = "CORUM Complex ID"
    tsv

  end
end

iif CORUM.complexes.produce(true).find if __FILE__ == $0

