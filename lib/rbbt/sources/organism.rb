require 'rbbt-util'
require 'rbbt/util/resource'


module Organism
  extend Resource
  relative_to Rbbt, "share/organisms"

  class OrganismNotProcessedError < StandardError; end

  def self.datadir(org)
    File.join(Rbbt.datadir, 'organisms', org)
  end 

  def self.attach_translations(org, tsv, target = nil, fields = nil, options = {})
    Log.high "Attaching Translations for #{ org.inspect }, target #{target.inspect}, fields #{fields.inspect}"
    options = Misc.add_defaults options, :persistence => true, :case_insensitive => false

    options.merge! :key    => target unless target.nil?
    options.merge! :fields => fields unless fields.nil?

    index = identifiers(org).tsv options

    tsv.attach index, [:key]
  end

  def self.normalize(org, list, target = nil, fields = nil, options = {})
    return [] if list.nil? or list.empty?
    options = Misc.add_defaults options, :persistence => true, :case_insensitive => true, :double => false
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
    identifiers = TSV.new(Organism.identifiers(org), :persistence => true)
    field_matches = identifiers.field_matches(values)
    field_matches.sort_by{|field, matches| matches.uniq.length}.last
  end

  def self.organisms
    Dir.glob(File.join(Rbbt.share.organisms.find, '*')).collect{|f| File.basename(f)}
  end

  def self.name(organism)
    Organism.scientific_name(organism).read.strip
  end

  def self.organism(name)
    organisms.select{|organism|
      organism == name or Organism.name(organism) =~ /#{ name }/i
    }.first
  end

  def self.find_gene_at(org, chromosome, positions)
    chromosome = chromosome.to_s
    chromosome_bed = Persistence.persist(Organism.gene_positions(org), "Gene_positions[#{chromosome}]", :fwt, :chromosome => chromosome, :range => true) do |file, options|
      tsv = file.tsv(:persistence => false, :type => :list)
      tsv.select("Chromosome Name" => chromosome).collect do |gene, values|
        [gene, values.values_at("Gene Start", "Gene End").collect{|p| p.to_i}]
      end
    end

    if Array === positions
      positions.collect{|position| chromosome_bed[position]}.collect
    else
      chromosome_bed[positions]
    end
  end

  def self.find_transcript_at(org, chromosome, positions)
    chromosome = chromosome.to_s
    chromosome_bed = Persistence.persist(Organism.transcript_positions(org), "Transcript_positions[#{chromosome}]", :fwt, :chromosome => chromosome, :range => true) do |file, options|
      tsv = file.tsv(:persistence => false, :type => :list)
      tsv.select("Chromosome Name" => chromosome).collect do |transcript, values|
        [transcript, values.values_at("Transcript Start", "Transcript End").collect{|p| p.to_i}]
      end
    end

    if Array === positions
      positions.collect{|position| chromosome_bed[position]}.collect
    else
      chromosome_bed[positions]
    end
  end


  ["Hsa", "Sce"].each do |organism|
    rakefile = Rbbt["share/install/Organism/#{ organism }/Rakefile"]
    rakefile.lib_dir = Resource.caller_lib_dir __FILE__
    rakefile.pkgdir = 'phgx'
    Organism[organism].define_as_rake rakefile
    module_eval "#{ organism } = with_key '#{organism}'"
  end
end
