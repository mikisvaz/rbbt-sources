require 'rbbt'
require 'rbbt/util/open'
require 'rbbt/resource'
require 'rbbt/sources/cath'
require 'rbbt/sources/uniprot'

module UniProt
  extend Resource
  self.subdir = "share/databases/UniProt"

  UniProt.claim UniProt.annotated_variants, :proc do
    url = "http://www.uniprot.org/docs/humsavar.txt"
    tsv = TSV.open(CMD.cmd('tail -n +31 | head -n -4|grep "[[:alpha:]]"', :in => Open.open(url), :pipe => true), 
                   :fix => Proc.new{|line| parts = line.split(/\s+/); (parts[1..5] + [(parts[6..-1] || []) * " "]) * "\t"}, 
                   :type => :double,
                   :merge => true,
                   :key_field => "UniProt/SwissProt Accession",
                   :fields => ["UniProt Variant ID", "Amino Acid Mutation", "Type of Variant", "SNP ID", "Disease"])

    tsv.unnamed = true
    tsv.process "Amino Acid Mutation" do |mutations|
      mutations.collect do |mutation|
        if mutation.match(/p\.(\w{3})(\d+)(\w{3})/)
          wt = Misc::THREE_TO_ONE_AA_CODE[$1.downcase]
          mut = Misc::THREE_TO_ONE_AA_CODE[$3.downcase]
          [wt, $2, mut] * ""
        else
          mutation
        end
      end
    end
    tsv.to_s
  end

  def self.get_uniprot_entry(uniprotids)
    _array = Array === uniprotids

    uniprotids = [uniprotids] unless Array === uniprotids
    uniprotids = uniprotids.compact.collect{|id| id}

    result_files = FileCache.cache_online_elements(uniprotids, 'uniprot-{ID}.xml') do |ids|
      result = {}
      ids.each do |id|
        begin
          Misc.try3times do

            content = Open.read(UNIPROT_TEXT.sub("[PROTEIN]", id), :wget_options => {:quiet => true}, :nocache => true)

            result[id] = content
          end
        rescue
          Log.error $!.message
        end
      end
    end

    uniprots = {}
    uniprotids.each{|id| uniprots[id] = Open.read(result_files[id]) }

    if _array
      uniprots
    else
      uniprots.values.first
    end
  end

  UNIPROT_TEXT="http://www.uniprot.org/uniprot/[PROTEIN].txt"
  UNIPROT_FASTA="http://www.uniprot.org/uniprot/[PROTEIN].fasta"
  def self.pdbs(protein)
    url = UNIPROT_TEXT.sub "[PROTEIN]", protein
    text = Open.read(url)

    pdb = {}

    text.split(/\n/).each{|l| 
      next unless l =~ /^DR\s+PDB; (.*)\./
      id, method, resolution, region = $1.split(";").collect{|v| v.strip}
      begin
        chains, start, eend = region.match(/(\w+)=(\d+)-(\d+)/).values_at(1,2,3)
        start = start.to_i
        eend = eend.to_i
        start, eend = eend, start if start > eend
      rescue
        Log.warn("Error process Uniprot PDB line: #{line}")
        next
      end
      pdb[id.downcase] = {:method => method, :resolution => resolution, :region => (start..eend), :chains => chains}
    }
    pdb
  end

  def self.sequence(protein)
    url = UNIPROT_FASTA.sub "[PROTEIN]", protein
    text = Open.read(url)

    text.split(/\n/).select{|line| line !~ /^>/} * ""
  end

  def self.features(protein)
    #url = UNIPROT_TEXT.sub "[PROTEIN]", protein
    #text = Open.read(url)
    text = get_uniprot_entry(protein)

    text = text.split(/\n/).select{|line| line =~ /^FT/} * "\n"

    parts = text.split(/^(FT   \w+)/)
    parts.shift

    features = []

    type = nil
    parts.each do |part|
      parts
      if part[0..1] == "FT"
        type = part.gsub(/FT\s+/,'')
        next
      end
      value = part.gsub("\nFT", '').gsub(/\s+/, ' ')
      case
      when value.match(/(\d+) (\d+) (.*)/)
        start, eend, description = $1, $2, $3
        description.gsub(/^FT\s+/m, '')
      when value.match(/(\d+) (\d+)/)
        start, eend = $1, $2
        description = nil
      else
        Log.debug "Value not understood: #{ value }"
      end


      feature = {
        :type => type,
        :start => start.to_i, 
        :end => eend.to_i, 
        :description => description,
      }

      features << feature
    end

    features
  end


  def self.variants(protein)
    url = UNIPROT_TEXT.sub "[PROTEIN]", protein
    text = Open.read(url)

    text = text.split(/\n/).select{|line| line =~ /^FT/} * "\n"

    parts = text.split(/^(FT   \w+)/)
    parts.shift

    variants = []

    type = nil
    parts.each do |part|
      if type.nil?
        type = part
      else
        if type !~ /VARIANT/
          type = nil
          next
        end
        type = nil
        
        value = part.gsub("\nFT", '').gsub(/\s+/, ' ')
        # 291 291 K -> E (in sporadic cancers; somatic mutation). /FTId=VAR_045413.
        case
        when value.match(/(\d+) (\d+) ([A-Z])\s*\-\>\s*([A-Z]) (.*)\. \/FTId=(.*)/)
          start, eend, ref, mut, desc, id = $1, $2, $3, $4, $5, $6
        when value.match(/(\d+) (\d+) (.*)\. \/FTId=(.*)/)
          start, eend, ref, mut, desc, id = $1, $2, nil, nil, $3, $4
        else
          Log.debug "Value not understood: #{ value }"
        end
        variants << {
          :start => start, 
          :end => eend, 
          :ref => ref,
          :mut => mut, 
          :desc => desc, 
          :id => id,
        }
      end
    end

    variants
  end

  def self.cath(protein)
    url = UNIPROT_TEXT.sub "[PROTEIN]", protein
    text = Open.read(url)

    cath = {}
    text.split(/\n/).each{|l| 
      next unless l =~ /^DR\s+Gene3D; G3DSA:(.*)\./
      id, description, cuantity = $1.split(";").collect{|v| v.strip}
      cath[id] = {:description => description, :cuantity => cuantity}
    }
    cath
  end

  def self.cath_domains(protein)
    pdbs = pdbs(protein).keys.uniq
    pdbs.collect do |pdb|
      Cath.domains_for_pdb(pdb)
    end.flatten.compact
  end

  def self.pdbs_covering_aa_position(protein, aa_position)
    UniProt.pdbs(protein).select do |pdb, info|
      info[:region].include? aa_position
    end
  end
end
