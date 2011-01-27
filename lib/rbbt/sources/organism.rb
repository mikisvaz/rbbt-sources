require 'rbbt-util'
require 'rbbt/util/data_module'

module Organism
  class OrganismNotProcessedError < StandardError; end

  def self.datadir(org)
    File.join(Rbbt.datadir, 'organisms', org)
  end 

  def self.normalize(org, list, options = {})
    options = Misc.add_defaults options, :persistence => true
    if Array === list
      TSV.index(Organism.identifiers(org), options).values_at(*list).collect{|r| r ?  r.first : nil}
    else
      r = TSV.index(Organism.identifiers(org), options)[list]
      r.nil? ? nil : r.first
    end
  end

  def self.guess_id(org, values)
    identifiers = TSV.new(Organism.identifiers(org), :persistence => true)
    field_matches = identifiers.field_matches(values)
    field_matches.sort_by{|field, matches| matches.uniq.length}.last
  end

  def self.organisms
    Dir.glob(File.join(PKGData.sharedir_for_file(__FILE__), 'install/Organism/*/Rakefile')).collect{|f| File.basename(File.dirname(f))}
  end

  def self.name(organism)
    Open.read(Organism.scientific_name(organism)).strip
  end

  def self.organism(name)
    organisms.select{|organism|
      organism == name or Organism.name(organism) =~ /#{ name }/i
    }.first
  end
  
  extend DataModule
  
  Hsa = with_key('Hsa')
  Sce = with_key('Sce')
end
