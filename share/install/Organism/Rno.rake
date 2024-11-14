$taxs = [10116]
$scientific_name = "Rattus norvegicus"

$biomart_db = 'rnorvegicus_gene_ensembl'
$biomart_db_germline_variation = 'rnorvegicus_snp'
$biomart_db_somatic_variation = 'rnorvegicus_snp_som'
$ortholog_key = "rnorvegicus_homolog_ensembl_gene"

$biomart_lexicon = [ 
  [ 'Associated Gene Name' , "external_gene_id"], 
  [ 'HGNC symbol', "hgnc_symbol"  ],
  [ 'HGNC automatic gene name', "hgnc_automatic_gene_name"  ],
  [ 'HGNC curated gene name ', "hgnc_curated_gene_name"  ],
]

$biomart_identifiers = [ 
  ['Entrez Gene ID', "entrezgene"],
  ['Ensembl Protein ID', "ensembl_peptide_id"  ],
  ['Associated Gene Name' , "external_gene_name"], 
  ['Protein ID' , "protein_id"] , 
  ['UniProt/SwissProt ID' , "uniprot_swissprot"] , 
  ['UniProt/SwissProt Accession' , "uniprot_swissprot_accession"] , 
  ['RefSeq Protein ID' , "refseq_peptide"] , 
  ['EMBL (Genbank) ID' , "embl"] , 
  ['RGD ID' , "rgd"] , 
  ['RGD Symbol' , "rgd_symbol"] , 
  #['Affy rae230a', "affy_rae230a"],
  #['Affy rae230b', "affy_rae230b"],
  #['Affy RaGene', "affy_ragene_1_0_st_v1"],
  #['Affy rat230 2', "affy_rat230_2"],
  #['Affy RaEx', "affy_raex_1_0_st_v1"],
  #['Affy rg u34a', "affy_rg_u34a"],
  #['Affy rg u34b', "affy_rg_u34b"],
  #['Affy rg u34c', "affy_rg_u34c"],
  #['Affy rn u34', "affy_rn_u34"],
  #['Affy rt u34', "affy_rt_u34"],
  #['Codelink ID ', "codelink"],
]

$biomart_protein_identifiers = [
  [ 'Protein ID', "protein_id"  ],
  [ 'RefSeq Protein ID', "refseq_peptide"  ],
  [ 'Unigene ID', "unigene"  ],
  [ 'UniProt/SwissProt ID', "uniprot_swissprot"],
  [ 'UniProt/SwissProt Accession', "uniprot_swissprot_accession"],
]

$namespace = File.basename(__FILE__).sub(/\.rake$/,'')
Thread.current["namespace"] = $namespace
load File.join(File.dirname(__FILE__), 'organism_helpers.rb')
