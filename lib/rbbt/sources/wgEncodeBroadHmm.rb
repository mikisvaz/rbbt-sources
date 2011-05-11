require 'rbbt'

module EBChromatin
  BASE_URL='http://hgdownload-test.cse.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeBroadHmm/'

  [ 'wgEncodeBroadHmmGm12878HMM.bed.gz',
    'wgEncodeBroadHmmH1hescHMM.bed.gz',
    'wgEncodeBroadHmmHmecHMM.bed.gz',
    'wgEncodeBroadHmmHsmmHMM.bed.gz',
    'wgEncodeBroadHmmHuvecHMM.bed.gz',
    'wgEncodeBroadHmmHepg2HMM.bed.gz',
    'wgEncodeBroadHmmK562HMM.bed.gz',
    'wgEncodeBroadHmmNhekHMM.bed.gz',
    'wgEncodeBroadHmmNhlfHMM.bed.gz'].each do |file|
      
      Rbbt.share.databases.EBChromatin[file.match(/wgEncodeBroadHmm(.*)HMM.bed.gz/)[1]].define_as_proc do 
        url = File.join(BASE_URL, file)

        CMD.cmd('sed \'s/^chr\([[:alnum:]]\+\)\t\([[:digit:]]\+\)\t\([[:digit:]]\+\)/\1:\2:\3\t\1\t\2\t\3/\' | cut -f 1,2,3,4,5 | awk \'BEGIN {print "#Region ID\tChromosome Name\tStart\tEnd\tType"} /./ {print $0}\' ', :in => Open.read(url), :pipe => true).read
      end
    end

  def self.chromosome(cell, chr, positions)
    list = Array === positions ? positions : [positions]

    file = Rbbt.share.databases.EBChromatin[cell]
    chromosome_bed = Persistence.persist(file, "EBChromatin[#{cell}][#{chr}]", :fwt, :chromosome => chr, :range => true) do |file, options|
      chromosome = options[:chromosome]
      tsv = file.tsv(:persistence => false, :type => :list, :grep => "^#{chromosome}:\\|^#")
      tsv.collect do |gene, values|
        [gene, values.values_at("Start", "End").collect{|p| p.to_i}]
      end
    end

    list.collect do |pos| chromosome_bed[pos] end
  end

end
