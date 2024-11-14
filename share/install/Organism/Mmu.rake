$taxs = [10090]
$scientific_name = "Mus musculus"
$ortholog_key = "mmusculus_homolog_ensembl_gene"

$biomart_db = 'mmusculus_gene_ensembl'
$biomart_db_germline_variation = 'mmusculus_snp'
$biomart_db_somatic_variation = 'mmusculus_snp_som'

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
  [ 'UniProt/SwissProt ID', "uniprot_swissprot"  ],
  [ 'UniProt/SwissProt Accession', "uniprot_swissprot_accession"  ],
]

$biomart_probe_identifiers = [
]

$biomart_identifiers = [ 
  [ 'Entrez Gene ID', "entrezgene"],
  [ 'Ensembl Protein ID', "ensembl_peptide_id"  ],
  [ 'MGI ID' , "mgi_id"] , 
  [ 'Associated Gene Name', "external_gene_name"  ],
  [ 'CCDS ID', "ccds"  ],
  [ 'Protein ID', "protein_id"  ],
  [ 'RefSeq Protein ID', "refseq_peptide"  ],
  [ 'Unigene ID', "unigene"  ],
  [ 'UniProt/SwissProt ID', "uniprot_swissprot"  ],
  [ 'UniProt/SwissProt Accession', "uniprot_swissprot_accession"  ],
  [ 'EMBL (Genbank) ID' , "embl"] , 
]

$namespace = File.basename(__FILE__).sub(/\.rake$/,'')
Thread.current["namespace"] = $namespace
load File.join(File.dirname(__FILE__), 'organism_helpers.rb')

