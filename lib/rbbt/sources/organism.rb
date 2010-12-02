require 'rbbt-util'

module Organism
  class OrganismNotProcessedError < StandardError; end

  Rbbt.add_datafiles 'Sce' => ['orgs', 'Sce']

  def self.datadir(org)
    File.join(Rbbt.datadir, 'organisms', org)
  end 
end
