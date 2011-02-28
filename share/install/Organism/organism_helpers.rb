$biomart_ensembl_gene = ['Ensembl Gene ID', 'ensembl_gene_id']
$biomart_ensembl_protein = ['Ensembl Protein ID', 'ensembl_peptide_id']
$biomart_ensembl_exon = ['Ensembl Exon ID', 'ensembl_exon_id']
$biomart_ensembl_transcript = ['Ensembl Transcript ID', 'ensembl_transcript_id']

$biomart_gene_positions = [
  ['Chromosome Name','chromosome_name'],
  ['Strand','strand'],
  ['Gene Start','start_position'],
  ['Gene End','end_position'],
]

$biomart_transcript = [
  ['Transcript Start (bp)','transcript_start'],
  ['Transcript End (bp)','transcript_end'],
  ['Ensembl Protein ID', 'ensembl_protein_id'],
]

$biomart_transcript_exons = [
  ['Exon Chr Start','exon_chrom_start'],
  ['Exon Chr End','exon_chrom_end'],
  ['Exon Strand','strand'],
  ['Exon Rank in Transcript','rank'],
  ['Constitutive Exon','is_constitutive'],
]

$biomart_gene_sequence = [
  ['Gene Sequence','gene_exon_intron'],
]

$biomart_protein_sequence = [
  ['Protein Sequence','peptide'],
]

$biomart_transcript_sequence = [
  ['cDNA','cdna'],
]

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

file 'transcripts' do |t|
  transcripts = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript, [])

  File.open(t.name, 'w') do |f| f.puts transcripts end
end

file 'gene_positions' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_positions, [])

  File.open(t.name, 'w') do |f| f.puts sequences end
end

file 'gene_sequence' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_sequence, [])

  File.open(t.name, 'w') do |f| f.puts sequences end
end

file 'protein_sequence' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_protein, $biomart_protein_sequence, [])

  File.open(t.name, 'w') do |f| f.puts sequences end
end

file 'transcript_exons' do |t|
  exons = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_exons, [])

  File.open(t.name, 'w') do |f| f.puts exons end
end

file 'transcript_sequence' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_sequence, [])

  File.open(t.name, 'w') do |f| f.puts sequences end
end

file 'gene_pmids' do |t|
  tsv =  Entrez.entrez2pubmed($taxs)
  text = "#Entrez Gene ID\tPMID"
  tsv.each do |gene, pmids|
    text << "\n" << gene << "\t" << pmids * "|"
  end
  Open.write(t.name, text)
end

