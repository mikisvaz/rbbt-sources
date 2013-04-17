require 'rbbt'

module Ensembl
  def self.releases
    @releases ||= Rbbt.share.Ensembl.release_dates.find.tsv :key_field => "build"
  end

  def self.org2release(organism)
    releases[organism.split("/").last || "current"]
  end
end


