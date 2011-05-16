require 'rbbt'

module EBChromatin
  BASE_URL='http://hgdownload-test.cse.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeBroadHmm/'

  TISSUES= %w(Gm12878 H1hesc Hmec Hsmm Huvec Hepg2 K562 Nhek Nhlf)
  
  TISSUES.each do |tissue|
    file = "wgEncodeBroadHmm#{tissue}HMM.bed.gz"

    Rbbt.share.databases.EBChromatin[file.match(/wgEncodeBroadHmm(.*)HMM.bed.gz/)[1]].define_as_proc do 
      url = File.join(BASE_URL, file)

      CMD.cmd('sed \'s/^chr\([[:alnum:]]\+\)\t\([[:digit:]]\+\)\t\([[:digit:]]\+\)/\1:\2:\3\t\1\t\2\t\3/\' | cut -f 1,2,3,4,5 | awk \'BEGIN {print "#Region ID\tChromosome Name\tStart\tEnd\tType"} /./ {print $0}\' ', :in => Open.read(url), :pipe => true).read
    end
  end

  def self.chromosome(tissue, chr, positions)
    list = Array === positions ? positions : [positions]

    file = Rbbt.share.databases.EBChromatin[tissue]
    chromosome_bed = Persistence.persist(file, "EBChromatin[#{tissue}][#{chr}]", :fwt, :chromosome => chr, :range => true) do |file, options|
      chromosome = options[:chromosome]
      tsv = file.tsv(:persistence => false, :type => :list, :grep => "^#{chromosome}:\\|^#")
      if tsv.size > 0
        tsv.collect do |gene, values|
          [gene, values.values_at("Start", "End").collect{|p| p.to_i}]
        end
      else
        raise "No chromatin information for chromosome #{ chr } in tissue #{ tissue }"
      end
    end

    list.collect do |pos| chromosome_bed[pos] end
  end

end
