require 'rbbt'
require 'rbbt/resource'

module COSMIC
  extend Resource
  self.subdir = "share/databases/COSMIC"

  COSMIC.claim COSMIC.mutations, :proc do 
    url = "ftp://ftp.sanger.ac.uk/pub/CGP/cosmic/data_export/CosmicCompleteExport_v63_300113.tsv.gz"

    tsv = TSV.open(Open.open(url), :type => :list, :header_hash => "", :key_field => "Mutation ID", :namespace => "Hsa/jun2011")
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
    tsv.to_s.gsub(/^(\d)/m,'COSM\1').gsub(/(\d)-(\d)/,'\1:\2')
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

