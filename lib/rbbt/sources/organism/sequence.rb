require 'rbbt/sources/organism'
require 'bio'
# Sequence analyses
module Organism

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
    ddd utr5

    raise "UTR5 for transcript #{ transcript } was missing" if utr5.nil?

    return nil if utr5 > offset
    sequence = transcript_sequence[transcript]
    raise "Sequence for transcript #{ transcript } was missing" if sequence.nil? if sequence.nil?

    range = (utr5..-1)
    sequence = sequence[range]

    ccds_offset = offset - utr5
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
        transcript_offsets[exon][transcript] = offset.to_i
      end
    end

    transcript_offsets
  end

  def self.genomic_position_transcript_offsets(org, positions, exon_offsets = nil, exon_start = nil)
    exon_offsets ||= Organism.exon_offsets(org).tsv(:double, :persistence => true)
    exon_start   ||= Organism.exons(org).tsv(:single, :persistence => true, :fields => ["Exon Chr Start"], :cast => :to_i)

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
          offset_in_exon = (pos.to_i - exon_start[exon].to_i) 
          position_offsets[position] ||= {}
          offsets[exon].each do |transcript, offset|
            if not offset.nil?
              position_offsets[position][transcript] = offset  + offset_in_exon
            end
          end
        end
      end
    end

    position_offsets
  end

  def self.genomic_mutation_to_protein_mutation(org, genomic_mutations)
    positions = genomic_mutations.keys.collect{|l| l.split(":")}

    # Prepare positions
    results = TSV.new({})
    results.key_field = "Position"
    results.fields = ["Ensembl Transcript ID", "Mutation"]
    results.type = :double

    # Prepare resources
    transcript_sequence = Organism.transcript_sequence(org).tsv(:single, :persistence => true)
    transcript_5utr     = Organism.transcript_5utr(org).tsv(:single, :persistence => true, :cast => 'to_i')

    # Find transcript ofsets from mutations
    offsets = Organism.genomic_position_transcript_offsets(org, positions)

    offsets.each do |position, transcripts|
      alleles = genomic_mutations[position * ":"].collect{|allele| Misc.IUPAC_to_base(allele)}.flatten

      transcripts.each do |transcript, offset|
        begin
          codon = Organism.codon_at_transcript_position(org, transcript, offset, transcript_sequence, transcript_5utr)
        rescue
          Log.medium $!.message
          next
        end

        if not codon.nil?
          alleles.each do |allele|
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

    ddd results
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
10	101557063	G	A
10	101559094	A	G
10	101560169	G	A
10	101563815	G	A
10	101565157	A	G
10	101572816	A	G
10	101578577	C	T
10	101578641	C	T
10	101578952	T	G
10	101591428	T	C
  EOF

  org = 'Hsa/may2009'

  #positions = TSV.new(StringIO.new(picmi_test), :list, :sep => /\s+/, :fix => Proc.new{|l| l.sub(/\s+/,':')})
  positions = TSV.new(File.join(ENV["HOME"], 'git/rbbt-util/integration_test/data/Metastasis.tsv'), :list, :fix => Proc.new{|l| l.sub(/\t/,':')})
  positions.key_field = "Position"
  positions.fields = %w(Reference Tumor)

  #positions =  positions.select ["10:98099540"]

  Organism.genomic_mutation_to_protein_mutation(org, positions.slice("Tumor"))
  Organism.genomic_mutation_to_protein_mutation("Hsa", positions.slice("Tumor"))
  exit

  exclusive_mutations = Open.read(File.join(ENV["HOME"], 'git/rbbt-util/integration_test/data/exclusive_mutations.tsv')).split(/\n/).collect{|l| l.split ":"}
  Log.severity = 0
  #
  #  i = -1
  #  positions.collect!{|l| i += 1; [l[0], (l[1].to_i + i).to_s]}
  #
  #  results = TSV.new({})
  #  results.key_field = "Position"
  #  results.fields = ["Ensembl Transcript ID", "Mutation"]
  #  results.type = :double
  #
  #  transcript_sequence = Organism.transcript_sequence(org).tsv(:single, :persistence => true)
  #  transcript_5utr = Organism.transcript_5utr(org).tsv(:single, :persistence => true, :cast => 'to_i')
  #  puts(Benchmark.measure do
  #    offsets = Organism.genomic_position_transcript_offsets(org, positions.keys.collect{|l| l.split(":")})
  #    ddd offsets
  #    #offsets = Organism.genomic_position_transcript_offsets(org, select)
  #    #offsets = Organism.genomic_position_transcript_offsets(org, exclusive_mutations)
  #    offsets.each do |position, transcripts|
  #      #puts position * ", "
  #      allele = positions[position * ":"]["Tumor"]
  #      transcripts.each do |transcript, offset|
  #        codon = Organism.codon_at_transcript_position(org, transcript, offset, transcript_sequence, transcript_5utr)
  #        if not codon.nil?
  #          change = Organism.codon_change(allele, *codon.values_at(0,1))
  #          pos_code = position * ":"
  #          mutation = [change.first, codon.last + 1, change.last] * ""
  #          if results.include? pos_code
  #            results[pos_code] = results[pos_code].merge [transcript, mutation]
  #          else
  #            results[pos_code] = [[transcript], [mutation]]
  #          end
  #        end
  #      end
  #    end
  #  end)
  #  ddd :end
  #  puts results["10:98099540"].inspect
  ##  puts results.to_s(results.keys.sort)
  ##  puts results.keys.length
end

