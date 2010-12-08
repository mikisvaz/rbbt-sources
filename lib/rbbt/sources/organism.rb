require 'rbbt-util'
require 'rbbt/util/data_module'

module Organism
  class OrganismNotProcessedError < StandardError; end

  def self.datadir(org)
    File.join(Rbbt.datadir, 'organisms', org)
  end 
  
  extend DataModule
  
  Hsa = with_key('Hsa')
  Sce = with_key('Sce')
end
