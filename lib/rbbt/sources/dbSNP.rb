require 'rbbt'
require 'rbbt/util/open'
require 'rbbt/resource'

module DbSNP
  extend Resource
  self.subdir = "share/databases/dbSNP"

  URL = "ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606/VCF/common_all.vcf.gz"

  DbSNP.claim DbSNP.mutations, :proc do
    tsv = TSV.setup({}, :key_field => "RS ID", :fields => ["Genomic Mutation"], :type => :single)
    file = Open.open(URL, :nocache => true) 
    while line = file.gets do
      next if line[0] == "#"[0]
      chr, position, id, ref, alt = line.split "\t"
      alt = alt.split(",").first
      if alt[0] == ref[0]
        alt[0] = '+'[0]
      end
      mutation = [chr, position, alt] * ":"

      tsv.namespace = "Hsa/may2012"
      tsv[id] = mutation
    end

    tsv.to_s
  end

  DbSNP.claim DbSNP.mutations_hg18, :proc do
    require 'rbbt/sources/organism'

    hg19_tsv = DbSNP.mutations.tsv :unnamed => true

    mutations = hg19_tsv.values

    translations = Misc.process_to_hash(mutations){|mutations| Organism.liftOver(mutations, "Hsa/jun2011", "Hsa/may2009")}

    tsv = hg19_tsv.process "Genomic Mutation" do |mutation|
      translations[mutation]
    end

    tsv.namespace = "Hsa/may2009"

    tsv.to_s
  end
end

