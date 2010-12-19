require 'rbbt-util'
require 'rbbt/util/data_module'

module Organism
  class OrganismNotProcessedError < StandardError; end

  def self.datadir(org)
    File.join(Rbbt.datadir, 'organisms', org)
  end 

  def self.normalize(org, list)
    TSV.index(Organism.identifiers(org), :persistence => true).values_at(*list).collect{|r| r ?  r.first : nil}
  end
  
  extend DataModule
  
  Hsa = with_key('Hsa')
  Sce = with_key('Sce')
end
