# Sequence analyses
module Organism

  def self.exon_offset_in_transcript(org, exon, transcript, exons = nil, transcript_exons = nil)
    exons            ||= Organism.exons(org).tsv(:persistence => true)
    transcript_exons ||= Organism.transcript_exons(org).tsv(:double, :fields => ["Ensembl Exon ID","Exon Rank in Transcript"], :persistence => true)

    sizes = []
    rank = nil
    transcript_exons[transcript].zip_fields.each do |_exon, _rank|
      _rank = _rank.to_i
      s, e = exons[_exon].values_at("Start", "End")
      sizes[_rank - 1] =  e.to_i - s.to_i
      rank = _rank if _exon == exon
    end

    if not rank.nil?
      sizes[0..rank - 1].inject(0){|e,acc| acc += e}
    else
      nil
    end
  end

  def self.coding_transcripts_for_exon(org, exon, exon_transcripts, transcript_info)
    exon_transcripts ||= Organism.transcript_exons(org).tsv(:double, :key => "Ensembl Exon ID", :fields => ["Ensembl Transcript ID"], :merge => true, :persistence => true )
    transcript_info  ||= Organism.transcripts.tsv(org).tsv(:list, :persistence => true )

    transcripts = exon_transcripts[exon].first
    transcripts.select{|transcript| transcript_info[transcript]["Ensembl Protein ID"].any?}
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

  def self.genes_at_chromosome_positions(org, chromosome, positions)
    chromosome = chromosome.to_s
    chromosome_bed = Persistence.persist(Organism.gene_positions(org), "Gene_positions[#{chromosome}]", :fwt, :chromosome => chromosome, :range => true) do |file, options|
      tsv = file.tsv(:persistence => false, :type => :list)
      tsv.select("Chromosome Name" => chromosome).collect do |gene, values|
        [gene, values.values_at("Gene Start", "Gene End").collect{|p| p.to_i}]
      end
    end

    if Array === positions
      positions.collect{|position| pos = chromosome_bed[position]; pos.nil? ? nil : pos.first}.collect
    else
      pos = chromosome_bed[positions];  
      pos.nil? ? nil : pos.first
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
        pos = chromosome_bed[position]; 
        pos.nil? ? nil : pos.first
      }
    else
      pos = chromosome_bed[positions];  
      pos.nil? ? nil : pos.first
    end
  end

end
