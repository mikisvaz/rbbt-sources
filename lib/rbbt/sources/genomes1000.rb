require 'rbbt'
require 'rbbt/util/open'
require 'rbbt/resource'

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

end

Genomes1000.mutations_alt.produce
