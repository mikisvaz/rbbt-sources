require 'rbbt'
require 'rbbt/util/open'
require 'rbbt/resource'
require 'net/ftp'

module DbSNP
  extend Resource
  self.subdir = "share/databases/dbSNP"

  NCBI_URL = "ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606/VCF/common_all.vcf.gz"

  DbSNP.claim DbSNP.mutations_ncbi, :proc do
    tsv = TSV.setup({}, :key_field => "RS ID", :fields => ["Genomic Mutation"], :type => :flat)
    file = Open.open(NCBI_URL, :nocache => true) 
    while line = file.gets do
      next if line[0] == "#"[0]
      chr, position, id, ref, alt = line.split "\t"

      mutations = alt.split(",").collect do |a|
        if alt[0] == ref[0]
          alt[0] = '+'[0]
        end
        [chr, position, alt] * ":"
      end

      tsv.namespace = "Hsa/may2012"
      tsv[id] = mutations
    end

    tsv.to_s
  end

  DbSNP.claim DbSNP.rsids, :proc do |filename|
    ftp = Net::FTP.new('ftp.broadinstitute.org')
    ftp.passive = true
    ftp.login('gsapubftp-anonymous', 'devnull@nomail.org')
    ftp.chdir('/bundle/2.3/hg19')

    tmpfile = TmpFile.tmp_file + '.gz'
    ftp.getbinaryfile('dbsnp_137.hg19.vcf.gz', tmpfile, 1024)

    file = Open.open(tmpfile, :nocache => true) 
    begin
      File.open(filename, 'w') do |f|
        f.puts "#: :type=:list#:namespace=Hsa/may2012"
        f.puts "#" + ["RS ID", "GMAF", "G5", "G5A", "dbSNP Build ID"] * "\t"
        while line = file.gets do
          next if line[0] == "#"[0]

          chr, position, id, ref, muts, qual, filter, info = line.split "\t"

          g5 = g5a = dbsnp_build_id = gmaf = nil

          gmaf = $1 if info =~ /GMAF=([0-9.]+)/
          g5 = true if info =~ /\bG5\b/
          g5a = true if info =~ /\bG5A\b/
          dbsnp_build_id = $1 if info =~ /dbSNPBuildID=(\d+)/

          f.puts [id, gmaf, g5, g5a, dbsnp_build_id] * "\t"
        end
      end
    rescue Exception
      FileUtils.rm filename if File.exists? filename
      raise $!
    ensure
      file.close
      FileUtils.rm tmpfile
    end

    nil
  end

  DbSNP.claim DbSNP.mutations, :proc do |filename|
    ftp = Net::FTP.new('ftp.broadinstitute.org')
    ftp.passive = true
    ftp.login('gsapubftp-anonymous', 'devnull@nomail.org')
    ftp.chdir('/bundle/2.3/hg19')

    tmpfile = TmpFile.tmp_file + '.gz'
    ftp.getbinaryfile('dbsnp_137.hg19.vcf.gz', tmpfile, 1024)

    file = Open.open(tmpfile, :nocache => true) 
    begin
      File.open(filename, 'w') do |f|
        f.puts "#: :type=:flat#:namespace=Hsa/may2012"
        f.puts "#" + ["RS ID", "Genomic Mutation"] * "\t"
        while line = file.gets do
          next if line[0] == "#"[0]

          chr, position, id, ref, muts, qual, filter, info = line.split "\t"

          chr.sub!('chr', '')

          position, muts = Misc.correct_vcf_mutation(position.to_i, ref, muts)

          mutations = muts.collect{|mut| [chr, position, mut] * ":" }

          f.puts ([id] + mutations) * "\t"
        end
      end
    rescue Exception
      FileUtils.rm filename if File.exists? filename
      raise $!
    ensure
      file.close
      FileUtils.rm tmpfile
    end

    nil
  end

  DbSNP.claim DbSNP.mutations_hg18, :proc do |filename|
    require 'rbbt/sources/organism'

    mutations = CMD.cmd("grep -v '^#'|cut -f 2|sort -u", :in => DbSNP.mutations.open).read.split("\n").collect{|l| l.split("|")}.flatten

    translations = Misc.process_to_hash(mutations){|mutations| Organism.liftOver(mutations, "Hsa/jun2011", "Hsa/may2009")}
    begin
      file = Open.open(DbSNP.mutations.find, :nocache => true) 
      File.open(filename, 'w') do |f|
        f.puts "#: :type=:flat#:namespace=Hsa/may2009"
        f.puts "#" + ["RS ID", "Genomic Mutation"] * "\t"
        while line = file.gets do
          next if line[0] == "#"[0]
          parts = line.split("\t")
          parts[1..-1] = parts[1..-1].collect{|p| translations[p]} * "|"
          f.puts parts * "\t"
        end
      end
    rescue Exception
      FileUtils.rm filename if File.exists? filename
      raise $!
    ensure
      file.close
    end

    nil
  end

  def self.rsid_index(organism, chromosome = nil)
    build = Organism.hg_build(organism)

    tag = [build, chromosome] * ":"
    Persist.persist("StaticPosIndex for dbSNP [#{ tag }]", :fwt, :persist => true) do
      value_size = 0
      file = DbSNP[build == "hg19" ? "mutations" : "mutations_hg18"]
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
    file = DbSNP[build == "hg19" ? "mutations" : "mutations_hg18"]
    @mutation_index ||= {}
    @mutation_index[build] ||= file.tsv :persist => true, :fields => ["Genomic Mutation"], :type => :single, :persist => true
  end

end

if defined? Entity
  if defined? Gene and Entity === Gene
    module Gene
      property :dbSNP_rsids => :single2array do
        DbSNP.rsid_index(organism, chromosome)[self.chr_range]
      end

      property :dbSNP_mutations => :single2array do
        GenomicMutation.setup(DbSNP.mutation_index(organism).values_at(*self.dbSNP_rsids).compact.flatten.uniq, "dbSNP mutations over #{self.name || self}", organism, true)
      end
    end
  end

  if defined? GenomicMutation and Entity === GenomicMutation
    module GenomicMutation
      property :dbSNP => :array2single do
        dbSNP.mutations.tsv(:persist => true, :key_field => "Genomic Mutation", :fields => ["RS ID"], :type => :single).values_at *self
      end
    end

  end
end

