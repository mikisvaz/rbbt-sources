require 'rbbt-util'
require 'rbbt/resource'

module GTRD
  extend Resource
  self.subdir = 'share/databases/GTRD'

  def self.organism(org="Hsa")
    Organism.default_code(org)
  end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib


  GTRD.claim GTRD.tfClass, :proc do 
    url = "http://gtrd.biouml.org/downloads/current/tfClass2ensembl.txt.gz"
    CMD.cmd("grep Homo | cut -f 2", :in => Open.read(url)).read
  end
end

iif GTRD.tfClass.produce.find if __FILE__ == $0

