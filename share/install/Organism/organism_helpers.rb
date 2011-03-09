$biomart_ensembl_gene = ['Ensembl Gene ID', 'ensembl_gene_id']
$biomart_ensembl_protein = ['Ensembl Protein ID', 'ensembl_peptide_id']
$biomart_ensembl_exon = ['Ensembl Exon ID', 'ensembl_exon_id']
$biomart_ensembl_transcript = ['Ensembl Transcript ID', 'ensembl_transcript_id']
$biomart_somatic_variation_id = ['Variation ID', "somatic_reference_id" ]
$biomart_germline_variation_id = ['Variation ID', "external_id" ]

$biomart_gene_positions = [
  ['Chromosome Name','chromosome_name'],
  ['Strand','strand'],
  ['Gene Start','start_position'],
  ['Gene End','end_position'],
]

$biomart_gene_sequence = [
  ['Gene Sequence','gene_exon_intron'],
]

#{{{ Transcript

$biomart_gene_transcript = [
  $biomart_ensembl_transcript
]

$biomart_transcript = [
  ['Transcript Start (bp)','transcript_start'],
  ['Transcript End (bp)','transcript_end'],
  $biomart_ensembl_protein,
  $biomart_ensembl_gene
]

$biomart_transcript_sequence = [
  ['cDNA','cdna'],
]

$biomart_protein_sequence = [
  ['Protein Sequence','peptide'],
]

#{{{ Exons

$biomart_transcript_exons = [
  $biomart_ensembl_exon,
  ['Exon Rank in Transcript','rank'],
]

$biomart_exons = [
  $biomart_ensembl_exon,
  ['Exon Chr Start','exon_chrom_start'],
  ['Exon Chr End','exon_chrom_end'],
  ['Exon Strand','strand'],
  ['Constitutive Exon','is_constitutive'],
]

#{{{ Variations

$biomart_germline_variation_positions = [
  ['Chromosome Location (bp)', "chromosome_location" ],
  ['SNP Chromosome Strand', "snp_chromosome_strand" ],
  ['Transcript location (bp)', "transcript_location" ],
  ['Allele', "allele" ],
  ['Protein Allele', "peptide_shift" ],
  ['CDS Start', "cds_start_2076" ],
  ['CDS End', "cds_end_2076" ],
]

$biomart_germline_variations = [
    $biomart_ensembl_gene,
    ['Source', "source_name" ],
    ['Validated', "validated" ],
    ['Consequence Type', "synonymous_status" ],
]

$biomart_somatic_variation_positions = [
    ['Chromosome Location (bp)' , "somatic_chromosome_location" ] ,
    ['SNP Chromosome Strand' , "somatic_snp_chromosome_strand" ] ,
    ['Transcript location (bp)' , "somatic_transcript_location" ] ,
    ['Allele' , "somatic_allele" ] ,
    ['Protein Allele' , "somatic_peptide_shift" ] , 
    ['CDS Start' , "somatic_cds_start_2076" ] ,
    ['CDS End' , "somatic_cds_end_2076" ] , 
]

$biomart_somatic_variations = [
    $biomart_ensembl_gene,
    ['Source' , "somatic_source_name" ] ,
    ['Validated' , "somatic_validated" ] ,
    ['Consequence Type' , "somatic_synonymous_status" ] , 
]

#{{{ Rules

file 'scientific_name' do |t|
  File.open(t.name, 'w') do |f| f.write $scientific_name end
end

file 'identifiers' do |t|
  identifiers = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_identifiers, [])
  $biomart_identifiers.each do |name, key, prefix|
    if prefix
      identifiers.process name do |field, key, values| field.each{|v| v.replace "#{prefix}:#{v}"} end
    end
  end

  File.open(t.name, 'w') do |f| f.puts identifiers end
end

file 'gene_transcripts' do |t|
  transcripts = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_transcript, [], :keep_empty => tru)

  File.open(t.name, 'w') do |f| f.puts transcripts end
end

file 'transcripts' => 'gene_positions' do |t|
  transcripts = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript, [])
  transcripts.attach TSV.new('gene_positions'), "Chromosome Name"

  File.open(t.name, 'w') do |f| f.puts transcripts end
end

file 'gene_positions' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_positions, [])

  File.open(t.name, 'w') do |f| f.puts sequences end
end

file 'gene_sequence' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_sequence, [])

  # The output is swapped! Gene sequence is first and then ensembl gene id.
  kf = sequences.key_field
  sequences.key_field =  sequences.fields.first
  sequences.fields = [kf]

  File.open(t.name, 'w') do |f| f.puts sequences.reorder(kf).to_s end
end

file 'protein_sequence' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_protein, $biomart_protein_sequence, [])

  # The output is swapped! Gene sequence is first and then ensembl protein id.
  kf = sequences.key_field
  sequences.key_field = sequences.fields.first
  sequences.fields = [kf]

  File.open(t.name, 'w') do |f| f.puts sequences.reorder(kf).to_s end
end

file 'exons' do |t|
  exons = BioMart.tsv($biomart_db, $biomart_ensembl_exon, $biomart_exons, [])

  File.open(t.name, 'w') do |f| f.puts exons end
end

file 'transcript_exons' do |t|
  exons = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_exons, [], nil, :keep_empty => true)

  File.open(t.name, 'w') do |f| f.puts exons end
end

file 'transcript_sequence' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_sequence, [])

  # The output is swapped! Gene sequence is first and then ensembl gene id.
  kf = sequences.key_field
  sequences.key_field =  sequences.fields.first
  sequences.fields = [kf]

  File.open(t.name, 'w') do |f| f.puts sequences.reorder(kf).to_s end
end


file 'germline_variations' do |t|
  variations = BioMart.tsv($biomart_db, $biomart_germline_variation_id, $biomart_germline_variations, [], nil, :keep_empty => true)
  File.open(t.name, 'w') do |f| f.puts variations.to_s end
end

file 'germline_variation_positions' do |t|
  variations = BioMart.tsv($biomart_db, $biomart_germline_variation_id, $biomart_germline_variation_positions, [], nil, :keep_empty => true)
  File.open(t.name, 'w') do |f| f.puts variations.to_s end
end

file 'somatic_variations' do |t|
  variations = BioMart.tsv($biomart_db, $biomart_somatic_variation_id, $biomart_somatic_variations, [], nil, :keep_empty => true)
  File.open(t.name, 'w') do |f| f.puts variations.to_s end
end

file 'somatic_variation_positions' do |t|
  variations = BioMart.tsv($biomart_db, $biomart_somatic_variation_id, $biomart_somatic_variation_positions, [], nil, :keep_empty => true)
  File.open(t.name, 'w') do |f| f.puts variations.to_s end
end

file 'gene_pmids' do |t|
  tsv =  Entrez.entrez2pubmed($taxs)
  text = "#Entrez Gene ID\tPMID"
  tsv.each do |gene, pmids|
    text << "\n" << gene << "\t" << pmids * "|"
  end
  Open.write(t.name, text)
end


