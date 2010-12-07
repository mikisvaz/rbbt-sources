require 'rbbt-util'

module Organism
  class OrganismNotProcessedError < StandardError; end

  def self.datadir(org)
    File.join(Rbbt.datadir, 'organisms', org)
  end 

  def self.lexicon(org)
    datafile = org + '/lexicon'
    Rbbt.add_datafiles datafile => ['orgs', org]
    TSV.new(Rbbt.find_datafile(datafile), :persistence => true)
  end

  def self.identifiers(org)
    datafile = org + '/identifiers'
    Rbbt.add_datafiles datafile => ['orgs', org]
    TSV.new(Rbbt.find_datafile(datafile), :persistence => true)
  end
end
