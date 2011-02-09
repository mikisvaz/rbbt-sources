require 'rbbt-util'
require 'rbbt/util/data_module'


module Organism
  class OrganismNotProcessedError < StandardError; end

  def self.datadir(org)
    File.join(Rbbt.datadir, 'organisms', org)
  end 

  def self.attach_translations(org, tsv, target = nil, fields = nil, options = {})
    Log.high "Attaching Translations for #{ org.inspect }, target #{target.inspect}, fields #{fields.inspect}"
    options = Misc.add_defaults options, :persistence => true, :case_insensitive => true, :double => false
    double = Misc.process_options options, :double
   
    options.merge :target => target unless target.nil?
    options.merge :fields => fields unless fields.nil?

    index = identifiers(org).tsv :key => target, :fields => fields, :persistence => true

    tsv.attach index, [:key]
  end

  def self.normalize(org, list, target = nil, fields = nil, options = {})
    return [] if list.nil? or list.empty?
    options = Misc.add_defaults options, :persistence => true, :case_insensitive => true, :double => false
    double = Misc.process_options options, :double
   
    options.merge :target => target unless target.nil?
    options.merge :fields => fields unless fields.nil?

    index = identifiers(org).index options

    if Array === list
      if double
        index.values_at *list
      else
        index.values_at(*list).collect{|e| Misc.first e}
      end
    else
      if double
        index[list]
      else
        index[list].first
      end
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
    Organism.scientific_name(organism).read.strip
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
