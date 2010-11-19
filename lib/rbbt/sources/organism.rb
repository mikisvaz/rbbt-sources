require 'rbbt/util/base'
module Organism
  class OrganismNotProcessedError < StandardError; end

  def self.datadir(org)
    File.join(Rbbt.datadir, 'organisms', org)
  end 

end
