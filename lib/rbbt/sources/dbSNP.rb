require 'rbbt'
require 'rbbt/util/open'
require 'rbbt/resource'
require 'net/ftp'

module DbSNP
  extend Resource
  self.subdir = "share/databases/dbSNP"

  URL = "ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606/VCF/common_all.vcf.gz"

  DbSNP.claim DbSNP.mutations_ncbi, :proc do
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

  DbSNP.claim DbSNP._mutations, :proc do
    ftp = Net::FTP.new('ftp.broadinstitute.org')
    ftp.passive = true
    ftp.login('gsapubftp-anonymous', 'devnull@nomail.org')
    ftp.chdir('/bundle/2.3/hg19')

    tmpfile = TmpFile.tmp_file + '.gz'
    ftp.getbinaryfile('dbsnp_137.hg19.vcf.gz', tmpfile, 1024)

    tsv = TSV.setup({}, :key_field => "RS ID", :fields => ["Genomic Mutation", "GMAF", "G5", "G5A", "dbSNP Build ID"], :type => :list)
    file = Open.open(tmpfile, :nocache => true) 
    while line = file.gets do
      next if line[0] == "#"[0]

      chr, position, id, ref, mut, qual, filter, info = line.split "\t"

      chr.sub!('chr', '')

      mut = mut.split(",").first
      case
      when ref == '-'
        mut = "+" << mut
      when mut == '-'
        mut = "-" * ref.length
      when (mut.length > 1 and ref.length > 1)
        mut = '-' * ref.length << mut
      when (mut.length > 1 and ref.length == 1 and mut.index(ref) == 0)
        mut = '+' << mut[1..-1]
      when (mut.length == 1 and ref.length > 1 and ref.index(mut) == 0)
        mut = '-' * (ref.length - 1)
      else
        mut = mut
      end

      g5 = g5a = dbsnp_build_id = gmaf = nil
     
      gmaf = $1 if info =~ /GMAF=([0-9.]+)/
      g5 = true if info =~ /\bG5\b/
      g5a = true if info =~ /\bG5A\b/
      dbsnp_build_id = $1 if info =~ /dbSNPBuildID=(\d+)/

      mutation = [chr, position, mut] * ":"

      tsv.namespace = "Hsa/may2012"

      tsv[id] = [mutation, gmaf, g5, g5a, dbsnp_build_id]
    end
  end

  DbSNP.claim DbSNP.mutations, :proc do |filename|
    ftp = Net::FTP.new('ftp.broadinstitute.org')
    ftp.passive = true
    ftp.login('gsapubftp-anonymous', 'devnull@nomail.org')
    ftp.chdir('/bundle/2.3/hg19')

    tmpfile = TmpFile.tmp_file + '.gz'
    ftp.getbinaryfile('dbsnp_137.hg19.vcf.gz', tmpfile, 1024)

    begin
      File.open(filename, 'w') do |f|
        f.puts "#: :type=:list#:namespace=Hsa/may2012"
        f.puts "#" + ["RS ID", "Genomic Mutation", "GMAF", "G5", "G5A", "dbSNP Build ID"] * "\t"
        tsv = TSV.setup({}, :key_field => "RS ID", :fields => ["Genomic Mutation", "GMAF", "G5", "G5A", "dbSNP Build ID"], :type => :list)
        file = Open.open(tmpfile, :nocache => true) 
        while line = file.gets do
          next if line[0] == "#"[0]

          chr, position, id, ref, mut, qual, filter, info = line.split "\t"

          chr.sub!('chr', '')

          mut = mut.split(",").first
          case
          when ref == '-'
            mut = "+" << mut
          when mut == '-'
            mut = "-" * ref.length
          when (mut.length > 1 and ref.length > 1)
            mut = '-' * ref.length << mut
          when (mut.length > 1 and ref.length == 1 and mut.index(ref) == 0)
            mut = '+' << mut[1..-1]
          when (mut.length == 1 and ref.length > 1 and ref.index(mut) == 0)
            mut = '-' * (ref.length - 1)
          else
            mut = mut
          end

          g5 = g5a = dbsnp_build_id = gmaf = nil

          gmaf = $1 if info =~ /GMAF=([0-9.]+)/
          g5 = true if info =~ /\bG5\b/
          g5a = true if info =~ /\bG5A\b/
          dbsnp_build_id = $1 if info =~ /dbSNPBuildID=(\d+)/

          mutation = [chr, position, mut] * ":"

          f.puts [id, mutation, gmaf, g5, g5a, dbsnp_build_id] * "\t"

        end
      end
    rescue
      FileUtils.rm filename if File.exists? filename
    ensure
      FileUtils.rm tmpfile
    end

    nil
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
