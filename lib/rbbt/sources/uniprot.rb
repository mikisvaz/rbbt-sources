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


  UNIPROT_TEXT="http://www.uniprot.org/uniprot/[PROTEIN].txt"
  def self.pdbs(protein)
    url = UNIPROT_TEXT.sub "[PROTEIN]", protein
    text = Open.read(url)

    pdb = {}

    text.split(/\n/).each{|l| 
      next unless l =~ /^DR\s+PDB; (.*)\./
      id, method, resolution, region = $1.split(";").collect{|v| v.strip}
      begin
        chains, start, eend = region.match(/(\w+)=(\d+)-(\d+)/).values_at(1,2,3)
      rescue
        Log.warn("Error process Uniprot PDB line: #{line}")
        next
      end
      pdb[id.downcase] = {:method => method, :resolution => resolution, :region => (start.to_i..eend.to_i), :chains => chains}
    }
    pdb
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
