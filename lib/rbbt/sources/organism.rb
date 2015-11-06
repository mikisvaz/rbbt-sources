require 'rbbt'
require 'rbbt/resource'

module Organism
  extend Resource
  self.pkgdir = "rbbt"
  self.subdir = "share/organisms"

  ARCHIVE_MONTH_INDEX = {}
  %w(jan feb mar apr may jun jul aug sep oct nov dec).each_with_index{|d,i| ARCHIVE_MONTH_INDEX[d] = i }
  def self.compare_archives(a1, a2)
    a1 = a1.partition("/").last if a1 and a1.include? "/"
    a2 = a2.partition("/").last if a2 and a2.include? "/"
    return 0 if a1 == a2
    return -1 if a1 and a2.nil?
    return 1 if a1.nil? and a2

    m1,y1 = a1.match(/(...)(\d+)/).values_at 1, 2
    m2,y2 = a2.match(/(...)(\d+)/).values_at 1, 2

    y1 = y1.to_f
    y2 = y2.to_f

    ycmp = y1 <=> y2
    return ycmp unless ycmp == 0

    ARCHIVE_MONTH_INDEX[m1] <=> ARCHIVE_MONTH_INDEX[m2]
  end

  def self.default_code(organism = "Hsa")
    organism.split("/").first << "/feb2014"
  end

  def self.organism_codes(organism = nil)
    if organism
      Rbbt.etc.allowed_biomart_archives.list.collect{|build| [organism, build] * "/" }
    else
      Rbbt.etc.organisms.list.collect{|organism|
        organism =~ /\// ? organism : Rbbt.etc.allowed_biomart_archives.list.collect{|build| [organism, build] * "/" } + [organism]
      }.flatten.compact.uniq 
    end
  end

  def self.installed_organisms
    Rbbt.share.install.Organism.find.glob('???').collect{|f| File.basename(f)}
  end

  def self.installable_organisms
    self.installed_organisms
  end

  def self.allowed_biomart_archives
    Rbbt.etc.allowed_biomart_archives.exists? ? 
      Rbbt.etc.allowed_biomart_archives.list :
      nil
  end

  Organism.installable_organisms.each do |organism|
    claim Organism[organism], :rake, Rbbt.share.install.Organism[organism].Rakefile.find

    module_eval "#{ organism } = with_key '#{organism}'"
  end

  Rbbt.claim Rbbt.software.opt.bin.liftOver, :url, "http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver"

  def self.hg_build(organism)
    require 'rbbt/sources/ensembl_ftp'

    raise "Only organism 'Hsa' (Homo sapiens) supported" unless organism =~ /^Hsa/

    return 'hg20' unless organism =~ /\//
    date = organism.split("/")[1] 

    release = Ensembl.releases[date]

    release_number = release.sub(/.*-/,'').to_i
    if release_number <= 54 
      'hg18'
    elsif release_number <= 75
      'hg19'
    else
      'hg20'
    end
  end

  def self.liftOver(positions, source, target)

    source_hg = hg_build(source)
    target_hg = hg_build(target)

    case
    when (source_hg == 'hg19' and target_hg == 'hg18')
      map_url = "http://hgdownload.cse.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg18.over.chain.gz" 
    when (source_hg == 'hg18' and target_hg == 'hg19')
      map_url = "http://hgdownload.cse.ucsc.edu/goldenPath/hg18/liftOver/hg18ToHg19.over.chain.gz" 
    else
      return positions
    end

    positions_bed = positions.collect{|position| 
      chr, pos = position.split(":").values_at(0,1)
      ["chr" << chr, pos.to_i-1, pos, position] * "\t"
    } * "\n" + "\n"

    new_positions = {}

    TmpFile.with_file(positions_bed) do |source_bed|
      TmpFile.with_file() do |unmapped_file|
        TmpFile.with_file() do |map_file|


          Open.write(map_file, Open.read(map_url))
          new_mutations = TmpFile.with_file() do |target_bed|
            FileUtils.chmod(755, Rbbt.software.opt.bin.liftOver.produce.find)
            CMD.cmd("#{Rbbt.software.opt.bin.liftOver.find} '#{source_bed}' '#{map_file}' '#{target_bed}' '#{unmapped_file}'").read
            Open.read(target_bed) do |line|
              chr, position_alt, position, name = line.chomp.split("\t")
              chr.sub! /chr/, ''

              old_chr, old_position, *rest = name.split(":")
              new_positions[name] = ([chr, position].concat rest) * ":"
            end
          end
        end
      end
    end

    positions.collect do |position|
      new_positions[position]
    end
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
    Organism[organism]["scientific_name"].produce.read.strip
  end

  def self.organism(name)
    organisms.select{|organism|
      organism == name or Organism.scientific_name(organism) =~ /#{ name }/i
    }.first
  end

  def self.organism_code(name)
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

  def self.gene_list_bases(genes, organism = nil)
    if genes.respond_to? :orgnanism
      organism = genes.organism if organism.nil?
      genes = genes.clean_annotations
    end

    organism ||= "Hsa"

    @@gene_start_end ||= {}
    gene_start_end = @@gene_start_end[organism] ||= Organism.gene_positions(organism).tsv(:persist => true, :key_field => "Ensembl Gene ID", :fields => ["Gene Start", "Gene End"], :type => :list, :cast => :to_i, :unmamed => true)

    ranges = genes.collect{|gene| 
      start, eend = gene_start_end[gene]
      if start.nil? or eend.nil?
        Log.low "Gene #{ gene } does not have range" 
        next 
      end
      (start..eend) 
    }.compact
    Misc.total_length(ranges)
  end

  def self.gene_list_exon_bases(genes, organism = nil)
    if genes.respond_to? :orgnanism
      organism = genes.organism if organism.nil?
      genes = genes.clean_annotations
    end

    organism ||= "Hsa"

    @@gene_exons_tsv ||= {}
    gene_exons = @@gene_exons_tsv[organism] ||= Organism.exons(organism).tsv(:persist => true, :key_field => "Ensembl Gene ID", :fields => ["Ensembl Exon ID"], :type => :flat, :merge => true, :unnamed => true)

    @@exon_range_tsv ||= {}
    exon_ranges = @@exon_range_tsv[organism] ||= Organism.exons(organism).tsv(:persist => true, :fields => ["Exon Chr Start", "Exon Chr End"], :type => :list, :cast => :to_i, :unnamed => true)

    exons = gene_exons.values_at(*genes).compact.flatten.uniq

    exon_ranges = exons.collect{|exon|
      if not exon_ranges.include? exon
        Log.low "Exon #{ exon } does not have range" 
        next 
      end
      pos = exon_ranges[exon]
      (pos.first..pos.last)
    }.compact
    
    Misc.total_length(exon_ranges)
  end
end
