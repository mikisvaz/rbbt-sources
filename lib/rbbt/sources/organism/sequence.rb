require 'rbbt/sources/organism'
require 'rbbt/util/workflow'
require 'bio'
# Sequence analyses
module Organism
  extend WorkFlow

  def self.coding_transcripts_for_exon(org, exon, exon_transcripts, transcript_info)
    exon_transcripts ||= Organism.transcript_exons(org).tsv(:double, :key => "Ensembl Exon ID", :fields => ["Ensembl Transcript ID"], :merge => true, :persistence => true )
    transcript_info  ||= Organism.transcripts.tsv(org).tsv(:list, :persistence => true )

    transcripts = exon_transcripts[exon].first
    transcripts.select{|transcript| transcript_info[transcript]["Ensembl Protein ID"].any?}
  end

  def self.codon_at_transcript_position(org, transcript, offset, transcript_sequence = nil, transcript_5utr = nil)
    transcript_sequence ||= Organism.transcript_sequence(org).tsv(:single, :persistence => true)
    transcript_5utr ||= Organism.transcript_5utr(org).tsv(:single, :persistence => true, :cast => 'to_i')

    utr5 = transcript_5utr[transcript]

    raise "UTR5 for transcript #{ transcript } was missing" if utr5.nil?

    return nil if utr5 > offset

    sequence = transcript_sequence[transcript]
    raise "Sequence for transcript #{ transcript } was missing" if sequence.nil? if sequence.nil?

    ccds_offset = offset - utr5
    return nil if ccds_offset > sequence.length

    range = (utr5..-1)
    sequence = sequence[range]

    codon = ccds_offset / 3
    codon_offset =  ccds_offset % 3

    [sequence[(codon * 3)..((codon + 1) * 3 - 1)], codon_offset, codon]
  end

  def self.codon_change(allele, codon, offset)
    original = Bio::Sequence::NA .new(codon).translate
    codon = codon.dup
    codon[offset] = allele
    new = Bio::Sequence::NA .new(codon).translate
    [original, new]
  end

  def self.genes_at_chromosome_positions(org, chromosome, positions)
    chromosome = chromosome.to_s
    chromosome_bed = Persistence.persist(Organism.gene_positions(org), "Gene_positions[#{chromosome}]", :fwt, :chromosome => chromosome, :range => true) do |file, options|
      tsv = file.tsv(:persistence => false, :type => :list)
      tsv.select("Chromosome Name" => chromosome).collect do |gene, values|
        [gene, values.values_at("Gene Start", "Gene End").collect{|p| p.to_i}]
      end
    end

    if Array === positions
      positions.collect{|position| pos = chromosome_bed[position]; pos.nil? ? nil : pos.first}
    else
      pos = chromosome_bed[positions];  
      pos.nil? ? nil : pos.first
    end
  end

  def self.genes_at_genomic_positions(org, positions)
    positions = [positions] unless Array === positions.first
    genes = []
    chromosomes = {}
    indices     = {}
    positions.each_with_index do |info,i|
      chr, pos = info
      chromosomes[chr] ||= []
      indices[chr] ||= []
      chromosomes[chr] << pos
      indices[chr] << i
    end

    chromosomes.each do |chr, pos_list|
      chr_genes = genes_at_chromosome_positions(org, chr, pos_list)
      chr_genes.zip(indices[chr]).each do |gene, index| genes[index] = gene end
    end

    genes
  end

  def self.exons_at_chromosome_positions(org, chromosome, positions)
    chromosome = chromosome.to_s
    chromosome_bed = Persistence.persist(Organism.exons(org), "Exon_positions[#{chromosome}]", :fwt, :chromosome => chromosome, :range => true) do |file, options|
      tsv = file.tsv(:persistence => true, :type => :list)
      tsv.select("Chromosome Name" => chromosome).collect do |exon, values|
        [exon, values.values_at("Exon Chr Start", "Exon Chr End").collect{|p| p.to_i}]
      end
    end

    if Array === positions
      positions.collect{|position| 
        chromosome_bed[position]; 
      }
    else
      chromosome_bed[positions];  
    end
  end


  def self.exons_at_genomic_positions(org, positions)
    positions = [positions] unless Array === positions.first

    exons = []
    chromosomes = {}
    indices     = {}
    positions.each_with_index do |info,i|
      chr, pos = info
      chromosomes[chr] ||= []
      indices[chr] ||= []
      chromosomes[chr] << pos
      indices[chr] << i
    end

    chromosomes.each do |chr, pos_list|
      chr_exons = exons_at_chromosome_positions(org, chr, pos_list)
      chr_exons.zip(indices[chr]).each do |exon, index| exons[index] = exon end
    end

    exons
  end

  def self.exon_offset_in_transcript(org, exon, transcript, exons = nil, transcript_exons = nil)
    exons            ||= Organism.exons(org).tsv(:persistence => true)
    transcript_exons ||= Organism.transcript_exons(org).tsv(:double, :fields => ["Ensembl Exon ID","Exon Rank in Transcript"], :persistence => true)

    sizes = [0]
    rank = nil
    transcript_exons[transcript].zip_fields.each do |_exon, _rank|
      _rank = _rank.to_i
      s, e = exons[_exon].values_at("Start", "End")
      size = e.to_i - s.to_i + 1 
      sizes[_rank] =  size
      rank = _rank if _exon == exon
    end

    if not rank.nil?
      sizes[0..rank - 1].inject(0){|e,acc| acc += e}
    else
      nil
    end
  end

  def self.exon_transcript_offsets(org, exons, exon_offsets = nil, exon_info = nil)
    exon_info       ||= Organism.exons(org).tsv(:persistence => true)
    exon_offsets    ||= Organism.exon_offsets(org).tsv(:double, :persistence => true)

    exons = [exons] unless Array === exons
    transcript_offsets = {}
    exons.each do |exon|
      transcript_offsets[exon] ||= {}
      offsets = exon_offsets[exon].zip_fields

      offsets.collect do |transcript, offset|
        next if transcript.empty?
        transcript_offsets[exon][transcript] = offset.to_i
      end
    end

    transcript_offsets
  end

  def self.genomic_position_transcript_offsets(org, positions, exon_offsets = nil, exon_start = nil, exon_end = nil, exon_strand = nil)
    exon_offsets ||= Organism.exon_offsets(org).tsv(:double, :persistence => true)
    exon_start   ||= Organism.exons(org).tsv(:single, :persistence => true, :fields => ["Exon Chr Start"], :cast => :to_i)
    exon_end     ||= Organism.exons(org).tsv(:single, :persistence => true, :fields => ["Exon Chr End"], :cast => :to_i)
    exon_strand  ||= Organism.exons(org).tsv(:single, :persistence => true, :fields => ["Exon Strand"], :cast => :to_i)

    exons = exons_at_genomic_positions(org, positions)
    offsets        = Organism.exon_transcript_offsets(org, exons.flatten.uniq, exon_offsets, exon_info)

    position_exons = {}
    positions.zip(exons).each do |position,pos_exons| position_exons[position] = pos_exons end

    position_offsets = {}
    position_exons.each do |position,pos_exons|
      chr, pos = position
      next if pos_exons.nil? or pos_exons.empty?
      pos_exons.each do |exon|
        if offsets.include? exon
          if exon_strand[exon] == 1
            offset_in_exon = (pos.to_i - exon_start[exon].to_i) 
          else
            offset_in_exon = (exon_end[exon] - pos.to_i) 
          end
          position_offsets[position] ||= {}
          offsets[exon].each do |transcript, offset|
            if not offset.nil?
              position_offsets[position][transcript] = [offset  + offset_in_exon, exon_strand[exon]]
            end
          end
        end
      end
    end

    position_offsets
  end

  task_option :org, "Organism", :string
  task_option :genomic_mutations, "Position (chr:position), Allele", :tsv
  task :genomic_mutation_to_protein_mutation => :tsv do |org, genomic_mutations|
    positions = genomic_mutations.keys.collect{|l| l.split(":")}

    step(:prepare, "Prepare Results")
    results = TSV.new({})
    results.key_field = "Position"
    results.fields = ["Ensembl Transcript ID", "Mutation"]
    results.type = :double

    step(:resources, "Load Resources")
    transcript_sequence = Organism.transcript_sequence(org).tsv(:single, :persistence => true)
    transcript_5utr     = Organism.transcript_5utr(org).tsv(:single, :persistence => true, :cast => 'to_i')
    exon_offsets        = Organism.exon_offsets(org).tsv(:double, :persistence => true)
    exon_start          = Organism.exons(org).tsv(:single, :persistence => true, :fields => ["Exon Chr Start"], :cast => :to_i)
    exon_end            = Organism.exons(org).tsv(:single, :persistence => true, :fields => ["Exon Chr End"], :cast => :to_i)
    exon_strand         = Organism.exons(org).tsv(:single, :persistence => true, :fields => ["Exon Strand"], :cast => :to_i)

    step(:offsets, "Find transcripts and offsets for mutations")
    offsets = Organism.genomic_position_transcript_offsets(org, positions, exon_offsets, exon_start, exon_end, exon_strand)

    step(:aminoacid, "Translate mutation to amino acid substitutions")
    offsets.each do |position, transcripts|
      alleles = genomic_mutations[position * ":"].collect{|allele| Misc.IUPAC_to_base(allele)}.flatten

      transcripts.each do |transcript, offset_info|
        offset, strand = offset_info
        ddd strand
        begin
          codon = Organism.codon_at_transcript_position(org, transcript, offset, transcript_sequence, transcript_5utr)
        rescue
          Log.medium $!.message
          next
        end

        ddd codon
        if not codon.nil?
          alleles.each do |allele|
            ddd allele
            allele = Misc::BASE2COMPLEMENT[allele] if strand == -1
            ddd allele
            change = Organism.codon_change(allele, *codon.values_at(0,1))
            pos_code = position * ":"
            mutation = [change.first, codon.last + 1, change.last] * ""
            if results.include? pos_code
              results[pos_code] = results[pos_code].merge [transcript, mutation]
            else
              results[pos_code] = [[transcript], [mutation]]
            end
          end
        end
      end

    end

    results
  end
end

if __FILE__ == $0
  require 'rbbt/util/log'
  require 'benchmark'

  select = <<-EOF
3:64581875
  EOF
  select = select.split("\n").collect{|l| l.split(":")}

  picmi_test = <<-EOF
#Chromosome	Name	Position	Reference	Tumor
1	100382265	C	G
1	100380997	A	G
22	30163533	A	C
X	10094215	G	A
X	10085674	C	T
20	50071099	G	T
21	19638426	G	T
2	230633386	C	T
2	230312220	C	T
1	100624830	T	A
4	30723053	G	T 
  EOF

  # Build 37
  picmi_test = <<-EOF
#Chromosome	Name	Position	Reference	Tumor
1	100624830	T	A
21 19638426 G T
  EOF


#  # Build 36
#  picmi_test = <<-EOF
##Chromosome	Name	Position	Reference	Tumor
#3 81780820 T C
#2 43881517 A T
#2 43857514 T C
#6 88375602 G A
#16 69875502 G T
#16 69876078 T C
#16 69877147 G A
#17 8101874 C T 
#  EOF


  Log.severity = 2
  org = 'Hsa/may2009'
  file = File.join(ENV["HOME"], 'git/rbbt-util/integration_test/data/Metastasis.tsv')

  #positions = TSV.new(StringIO.new(picmi_test), :list, :sep => /\s+/, :fix => Proc.new{|l| l.sub(/\s+/,':')})
  positions = TSV.new(file, :list, :fix => Proc.new{|l| l.sub(/\t/,':')})
  positions.key_field = "Position"
  positions.fields = %w(Reference Control Tumor)
  #positions.fields = %w(Reference Tumor)

  #puts positions.slice(["Reference", "Tumor"]).to_s.split(/\n/).collect{|line| next if line =~ /#/; parts = line.split(/\t|:/); parts[3] = Misc.IUPAC_to_base(parts[3]).first; parts * ","}.compact * "\n"


  #positions =  positions.select ["10:98099540"]

  Organism.basedir = Rbbt.tmp.organism.sequence.jobs.find :user
  job =  Organism.job :genomic_mutation_to_protein_mutation, "Metastasis", org, positions.slice("Tumor")
  job.run

  while not job.done?
    puts job.step
    sleep 2
  end

  raise job.messages.last if job.error?
  mutations = job.load

end
