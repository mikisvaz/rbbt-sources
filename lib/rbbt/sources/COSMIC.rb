require 'rbbt'
require 'rbbt/resource'

module COSMIC
  extend Resource
  self.subdir = "share/databases/COSMIC"

  COSMIC.claim COSMIC.mutations, :proc do 
    url = "ftp://ftp.sanger.ac.uk/pub/CGP/cosmic/data_export/CosmicCompleteExport_v64_260313.tsv.gz"

    stream = CMD.cmd('awk \'BEGIN{FS="\t"} { if ($12 != "" && $12 != "Mutation ID") { sub($12, "COSM" $12 ":" $4)}; print}\'', :in => Open.open(url), :pipe => true)
    tsv = TSV.open(stream, :type => :list, :header_hash => "", :key_field => "Mutation ID", :namespace => "Hsa/jun2011")
    tsv.fields = tsv.fields.collect{|f| f == "Gene name" ? "Associated Gene Name" : f}
    tsv.add_field "Genomic Mutation" do |mid, values|
      position = values["Mutation GRCh37 genome position"]
      cds = values["Mutation CDS"]

      if position.nil? or position.empty?
        nil
      else
        position = position.split("-").first

        chr, pos = position.split(":")
        chr = "X" if chr == "23"
        chr = "Y" if chr == "24"
        chr = "M" if chr == "25"
        position = [chr, pos ] * ":"

        if cds.nil?
          position
        else
          change = case
                   when cds =~ />/
                     cds.split(">").last
                   when cds =~ /del/
                     deletion = cds.split("del").last
                     case
                     when deletion =~ /^\d+$/
                       "-" * deletion.to_i 
                     when deletion =~ /^[ACTG]+$/i
                       "-" * deletion.length
                     else
                       Log.debug "Unknown deletion: #{ deletion }"
                       deletion
                     end
                   when cds =~ /ins/
                     insertion = cds.split("ins").last
                     case
                     when insertion =~ /^\d+$/
                       "+" + "N" * insertion.to_i 
                     when insertion =~ /^[NACTG]+$/i
                       "+" + insertion
                     else
                       Log.debug "Unknown insertion: #{insertion }"
                       insertion
                     end
                   else
                     Log.debug "Unknown change: #{cds}"
                     "?(" << cds << ")"
                   end
          position + ":" + change
        end
      end
    end

    tsv.to_s.gsub(/(\d)-(\d)/,'\1:\2')
  end

  COSMIC.claim COSMIC.mutations_hg18, :proc do |filename|
    require 'rbbt/sources/organism'
    file = COSMIC.mutations.open
    begin

      while (line = file.gets) !~ /Genomic Mutation/; end
      fields = line[1..-2].split("\t")
      mutation_pos = fields.index "Genomic Mutation"

      mutations = CMD.cmd("grep -v '^#'|cut -f #{mutation_pos + 1}|sort -u", :in => COSMIC.mutations.open).read.split("\n").select{|m| m.include? ":" }

      translations = Misc.process_to_hash(mutations){|mutations| Organism.liftOver(mutations, "Hsa/jun2011", "Hsa/may2009")}

      File.open(filename, 'w') do |f|
        f.puts "#: :type=:list#:namespace=Hsa/may2009"
        f.puts "#" + fields * "\t"
        while line = file.gets do
          next if line[0] == "#"[0]
          line.strip!
          parts = line.split("\t")
          parts[mutation_pos] = translations[parts[mutation_pos]]
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
    Persist.persist("StaticPosIndex for COSMIC [#{ tag }]", :fwt, :persist => true) do
      value_size = 0
      file = COSMIC[build == "hg19" ? "mutations" : "mutations_hg18"]
      chr_positions = []
      Open.read(CMD.cmd("grep '\t#{chromosome}:'", :in => file.open, :pipe => true)) do |line|
        next if line[0] == "#"[0]
        rsid, mutation = line.split("\t").values_at 0, 25
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
    file = COSMIC[build == "hg19" ? "mutations" : "mutations_hg18"]
    @mutation_index ||= {}
    @mutation_index[build] ||= file.tsv :persist => true, :fields => ["Genomic Mutation"], :type => :single, :persist => true
  end


end

if defined? Entity
  if defined? Gene and Entity === Gene
    module Gene
      property :COSMIC_rsids => :single2array do
        COSMIC.rsid_index(organism, chromosome)[self.chr_range]
      end

      property :COSMIC_mutations => :single2array do
        GenomicMutation.setup(COSMIC.mutation_index(organism).values_at(*self.COSMIC_rsids).uniq, "COSMIC mutations over #{self.name || self}", organism, true)
      end
    end
  end
end
