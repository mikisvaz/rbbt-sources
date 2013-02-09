require 'rbbt'
require 'rbbt/util/open'
require 'rbbt/resource'
require 'rbbt/entity/gene'

module Genomes1000
  extend Resource
  self.subdir = "share/databases/genomes_1000"

  RELEASE_URL = "ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20110521/ALL.wgs.phase1_release_v3.20101123.snps_indels_sv.sites.vcf.gz"

  Genomes1000.claim Genomes1000.mutations, :proc do |filename|

    begin
      Open.write(filename) do |file|
        file.puts "#: :type=:single#:namespace=Hsa"
        file.puts "#Variant ID\tGenomic Mutation"

        Open.read(RELEASE_URL) do |line|
          next if line[0] == "#"[0]

          chromosome, position, id, references, alternative, quality, filter, info = line.split("\t")

          file.puts [id, [chromosome, position, alternative] * ":"] * "\t"
        end
      end
    rescue
      FileUtils.rm filename if File.exists? filename
      raise $!
    end
    nil
  end


  Genomes1000.claim Genomes1000.mutations_hg18, :proc do
    require 'rbbt/sources/organism'

    hg19_tsv = Genomes1000.mutations.tsv :unnamed => true

    mutations = hg19_tsv.values

    translations = Misc.process_to_hash(mutations){|mutations| Organism.liftOver(mutations, "Hsa/jun2011", "Hsa/may2009")}

    tsv = hg19_tsv.process "Genomic Mutation" do |mutation|
      translations[mutation]
    end

    tsv.namespace = "Hsa/may2009"

    tsv.to_s
  end

  def self.rsid_index(organism, chromosome = nil)
    build = Organism.hg_build(organism)

    tag = [build, chromosome] * ":"
    Persist.persist("StaticPosIndex for Genomes1000 [#{ tag }]", :fwt, :persist => true) do
      value_size = 0
      file = Genomes1000[build == "hg19" ? "mutations" : "mutations_hg18"]
      chr_positions = []
      Open.read(CMD.cmd("grep '\t#{chromosome}:'", :in => file.open, :pipe => true)) do |line|
        next if line[0] == "#"[0]
        rsid, mutation = line.split("\t")
        next if mutation.nil? or mutation.empty?
        chr, pos = mutation.split(":")
        next if chr != chromosome or pos.nil? or pos.empty?
        chr_positions << [rsid, pos.to_i]
        value_size = rsid.length if rsid.length > value_size
      end
      fwt = FixWidthTable.new :memory, value_size
      fwt.add_point(chr_positions)
      fwt
    end
  end

  def self.mutation_index(organism)
    build = Organism.hg_build(organism)
    file = Genomes1000[build == "hg19" ? "mutations" : "mutations_hg18"]
    @mutation_index ||= {}
    @mutation_index[build] ||= file.tsv :persist => true, :fields => ["Genomic Mutation"], :type => :single, :persist => true
  end


end

if defined? Entity
  if defined? Gene and Entity === Gene
    module Gene
      property :genomes_1000_rsids => :single2array do
        Genomes1000.rsid_index(organism, chromosome)[self.chr_range]
      end

      property :genomes_1000_mutations => :single2array do
        GenomicMutation.setup(Genomes1000.mutation_index(organism).values_at(*self.genomes_1000_rsids).uniq, "1000 Genomes mutations over #{self.name || self}", organism, true)
      end
 
    end
  end
end
