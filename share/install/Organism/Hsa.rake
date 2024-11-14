$taxs = [9606]
$scientific_name = "Homo sapiens"
$ortholog_key = "hsapiens_homolog_ensembl_gene"

$biomart_db = 'hsapiens_gene_ensembl'
$biomart_db_germline_variation = 'hsapiens_snp'
$biomart_db_somatic_variation = 'hsapiens_snp_som'

$biomart_lexicon = [ 
  [ 'Associated Gene Name' , "external_gene_name"], 
  [ 'HGNC symbol', "hgnc_symbol"  ],
  [ 'HGNC automatic gene name', "hgnc_automatic_gene_name"  ],
  [ 'HGNC curated gene name ', "hgnc_curated_gene_name"  ],
]

$biomart_protein_identifiers = [
  [ 'Protein ID', "protein_id"  ],
  [ 'RefSeq Protein ID', "refseq_peptide"  ],
  [ 'Unigene ID', "unigene"  ],
  [ 'UniProt/SwissProt ID', "uniprot_swissprot"],
  [ 'UniProt/SwissProt Accession', "uniprot_swissprot_accession"],
]

$biomart_probe_identifiers = [
  [ 'AFFY HC G110', 'affy_hc_g110' ],
  [ 'AFFY HG FOCUS', 'affy_hg_focus' ],
  [ 'AFFY HG U133-PLUS-2', 'affy_hg_u133_plus_2' ],
  [ 'AFFY HG U133A_2', 'affy_hg_u133a_2' ],
  [ 'AFFY HG U133A', 'affy_hg_u133a' ],
  [ 'AFFY HG U133B', 'affy_hg_u133b' ],
  [ 'AFFY HG U95AV2', 'affy_hg_u95av2' ],
  [ 'AFFY HG U95B', 'affy_hg_u95b' ],
  [ 'AFFY HG U95C', 'affy_hg_u95c' ],
  [ 'AFFY HG U95D', 'affy_hg_u95d' ],
  [ 'AFFY HG U95E', 'affy_hg_u95e' ],
  [ 'AFFY HG U95A', 'affy_hg_u95a' ],
  [ 'AFFY HUGENEFL', 'affy_hugenefl' ],
  [ 'AFFY HuEx', 'affy_huex_1_0_st_v2', "HuEx" ],
  [ 'AFFY HuGene', 'affy_hugene_1_0_st_v1' ],
  [ 'AFFY U133 X3P', 'affy_u133_x3p' ],
  #[ 'Agilent WholeGenome',"agilent_wholegenome" ],
  [ 'Agilent CGH 44b', 'agilent_cgh_44b' ],
  [ 'Codelink ID', 'codelink' ],
  [ 'Illumina HumanWG 6 v2', 'illumina_humanwg_6_v2' ],
  [ 'Illumina HumanWG 6 v3', 'illumina_humanwg_6_v3' ],
  [ 'RefSeq mRNA' , "refseq_mrna"] , 
  [ 'RefSeq ncRNA' , "refseq_ncrna"] , 
  [ 'RefSeq mRNA predicted' , "refseq_mrna_predicted"] , 
  [ 'RefSeq ncRNA predicted' , "refseq_ncrna_predicted"] , 
]

$biomart_identifiers = [ 
  [ 'Entrez Gene ID', "entrezgene"],
  [ 'Ensembl Protein ID', "ensembl_peptide_id"  ],
  [ 'Associated Gene Name', "external_gene_name"  ],
  [ 'CCDS ID', "ccds"  ],
  [ 'Protein ID', "protein_id"  ],
  [ 'RefSeq mRNA' , "refseq_mrna"] , 
  [ 'RefSeq ncRNA' , "refseq_ncrna"] , 
  [ 'RefSeq mRNA predicted' , "refseq_mrna_predicted"] , 
  [ 'RefSeq ncRNA predicted' , "refseq_ncrna_predicted"] , 
  [ 'RefSeq Protein ID', "refseq_peptide"  ],
  [ 'Unigene ID', "unigene"  ],
  [ 'UniProt/SwissProt ID', "uniprot_swissprot"  ],
  [ 'UniProt/SwissProt Accession', "uniprot_swissprot_accession"  ],
  [ 'HGNC ID', "hgnc_id", 'HGNC'],
  #[ 'EMBL (Genbank) ID' , "embl"] , 

  # Probes
  [ 'AFFY HC G110', 'affy_hc_g110' ],
  [ 'AFFY HG FOCUS', 'affy_hg_focus' ],
  [ 'AFFY HG U133-PLUS-2', 'affy_hg_u133_plus_2' ],
  [ 'AFFY HG U133A_2', 'affy_hg_u133a_2' ],
  [ 'AFFY HG U133A', 'affy_hg_u133a' ],
  [ 'AFFY HG U133B', 'affy_hg_u133b' ],
  [ 'AFFY HG U95AV2', 'affy_hg_u95av2' ],
  [ 'AFFY HG U95B', 'affy_hg_u95b' ],
  [ 'AFFY HG U95C', 'affy_hg_u95c' ],
  [ 'AFFY HG U95D', 'affy_hg_u95d' ],
  [ 'AFFY HG U95E', 'affy_hg_u95e' ],
  [ 'AFFY HG U95A', 'affy_hg_u95a' ],
  [ 'AFFY HUGENEFL', 'affy_hugenefl' ],
  [ 'AFFY HuEx', 'affy_huex_1_0_st_v2', "HuEx" ],
  [ 'AFFY HuGene', 'affy_hugene_1_0_st_v1' ],
  [ 'AFFY U133 X3P', 'affy_u133_x3p' ],
  #[ 'Agilent WholeGenome',"agilent_wholegenome" ],
  [ 'Agilent CGH 44b', 'agilent_cgh_44b' ],
  [ 'Codelink ID', 'codelink' ],
  [ 'Illumina HumanWG 6 v2', 'illumina_humanwg_6_v2' ],
  [ 'Illumina HumanWG 6 v3', 'illumina_humanwg_6_v3' ],
]

$namespace = File.basename(__FILE__).sub(/\.rake$/,'')
Thread.current["namespace"] = $namespace
load Organism.rake_organism_helper

file 'regulators' do |t|
  regulatory_id = ['Regulatory stable ID', 'regulatory_stable_id']
  regulatory_fields = [
    ['Chromosome Name','chromosome_name'],
    ['Region Start', 'chromosome_start'],
    ['Region End', 'chromosome_end'],
    ['Feature type', 'feature_type_name'],
]
  regulators = BioMart.tsv('hsapiens_regulatory_feature', regulatory_id, regulatory_fields, [], nil, :type => :list, :namespace => Thread.current['namespace'])

  Misc.sensiblewrite(t.name, regulators.to_s)
end

file 'regulator_activity' do |t|
  regulatory_id = ['Regulatory stable ID', 'regulatory_stable_id']
  regulatory_fields = [
    ['Epigenome name','epigenome_name'],
    ['Activity', 'activity'],
]
  regulators = BioMart.tsv('hsapiens_regulatory_feature', regulatory_id, regulatory_fields, [], nil, :type => :double, :namespace => Thread.current['namespace'])

  Misc.sensiblewrite(t.name, regulators.to_s)
end
