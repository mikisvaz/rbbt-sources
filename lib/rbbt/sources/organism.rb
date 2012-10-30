require 'rbbt'
require 'rbbt/resource'

module Organism
  extend Resource
  self.pkgdir = "rbbt"
  self.subdir = "share/organisms"

  def self.installable_organisms
    Rbbt.share.install.Organism.find(:lib).glob('???').collect{|f| File.basename(f)}
  end

  Organism.installable_organisms.each do |organism|
    claim Organism[organism], :rake, Rbbt.share.install.Organism[organism].Rakefile.find

    module_eval "#{ organism } = with_key '#{organism}'"
  end

  class OrganismNotProcessedError < StandardError; end

  def self.attach_translations(org, tsv, target = nil, fields = nil, options = {})
    Log.high "Attaching Translations for #{ org.inspect }, target #{target.inspect}, fields #{fields.inspect}"
    options = Misc.add_defaults options, :persist => true, :case_insensitive => false

    options.merge! :key_field    => target unless target.nil?
    options.merge! :fields => fields unless fields.nil?

    index = identifiers(org).tsv options

    tsv.attach index, :fields => [:key], :persist_input => true
  end

  def self.normalize(org, list, target = nil, fields = nil, options = {})
    return [] if list.nil? or list.empty?
    options = Misc.add_defaults options, :persist => true, :case_insensitive => true, :double => false
    double = Misc.process_options options, :double


    options.merge! :target => target unless target.nil?
    options.merge! :fields => fields unless fields.nil?

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
    field_matches = TSV.field_match_counts(Organism.identifiers(org).find, values)
    field_matches.sort_by{|field, count| count.to_i}.last
  end

  def self.organisms
    Dir.glob(File.join(Organism.root.find, '*')).collect{|f| File.basename(f)}
  end

  def self.scientific_name(organism)
    Organism[organism]["scientific_name"].read.strip
  end

  def self.organism(name)
    organisms.select{|organism|
      organism == name or Organism.scientific_name(organism) =~ /#{ name }/i
    }.first
  end

  def self.known_ids(name)
    TSV::Parser.new(Organism.identifiers(name).open).all_fields
  end
  
  def self.entrez_taxid_organism(taxid)
    all_organisms = Organism.installable_organisms

    all_organisms.each do |organism|
      return organism if Organism.entrez_taxids(organism).read.split("\n").include? taxid.to_s
    end

    raise "No organism identified for taxid #{taxid}. Supported organism are: #{all_organisms * ", "}"
  end

end
