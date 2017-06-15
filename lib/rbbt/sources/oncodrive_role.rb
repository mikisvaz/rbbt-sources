require 'rbbt-util'
require 'rbbt/resource'
require 'rbbt/sources/organism'

module OncoDriveROLE
  extend Resource
  self.subdir = 'share/databases/OncoDriveROLE'

  def self.organism(org="Hsa")
    Organism.default_code(org)
  end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib


  OncoDriveROLE.claim OncoDriveROLE.Cancer5000, :proc do 
    url = "http://bg.upf.edu/oncodrive-role/session/26f1ae8615a9420110c0b1b9f68d9c09/download/downloadData?w="
    tsv = TSV.open(url, :header_hash => '', :type => :list, :namespace => OncoDriveROLE.organism)
    tsv.key_field = "Ensembl Gene ID"
    tsv.fields = ["Associated Gene Name", "Mode of action", "Value"]

    tsv.to_s
  end

  def self.oncogenes
    OncoDriveROLE.Cancer5000.tsv.select("Mode of action" => "Activating").keys
  end
end

iif OncoDriveROLE.Cancer5000.produce.find if __FILE__ == $0

