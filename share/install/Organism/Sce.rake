$taxs = [559292,4932]
$scientific_name = "Saccharomyces cerevisiae"
$ensembl_domain = 'fungi'
#$ortholog_key = "yeast_ensembl_gene"

$biomart_db = 'scerevisiae_eg_gene'

$biomart_lexicon = [ 
  [ 'Associated Gene Name' , "external_gene_name"], 
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
  [ 'Associated Gene Name', "external_gene_name"  ],
  [ 'Protein ID', "protein_id"  ],
  [ 'RefSeq Protein ID', "refseq_peptide"  ],
  [ 'UniProt/SwissProt ID', "uniprot_swissprot"  ],
  [ 'UniProt/SwissProt Accession', "uniprot_swissprot_accession"  ],
  [ 'EMBL (Genbank) ID' , "embl"] , 
  [ 'RefSeq DNA' , "refseq_dna"] , 
]

$namespace = File.basename(__FILE__).sub(/\.rake$/,'')
Thread.current["namespace"] = $namespace
Thread.current["ensembl_domain"] = $ensembl_domain
load File.join(File.dirname(__FILE__), 'organism_helpers.rb')
