require 'rbbt-util'
require 'rbbt/resource'

module MCLP
  extend Resource
  self.subdir = 'share/databases/MCLP'

  #def self.organism(org="Hsa")
  #  Organism.default_code(org)
  #end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib


  MCLP.claim MCLP.RPPA, :proc do 
    url = "http://tcpaportal.org/mclp/download/MCLP-v1.1-Level4.zip"
    tsv = TSV.open(url, :header_hash => "", :fix => Proc.new{|l| l.gsub("NA", "")}, :cast => :to_f)
    tsv.key_field = "Sample"
    tsv.to_s
  end
end

iif MCLP.RPPA.produce(true).find if __FILE__ == $0

