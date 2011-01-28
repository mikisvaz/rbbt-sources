require 'rbbt-util'

module Reactome

  Rbbt.claim "Reactome", 
    Proc.new do
      headers = ["Uniprot ID#1", "Ensembl Gene ID#2","Entrez Gene ID#1", "Uniprot ID#2", "Ensembl Gene ID#2", "Entrez Gene ID#2" , "Type", "Reaction", "PMID"]

      tsv = TSV.new(Open.open("http://www.reactome.org/download/current/homo_sapiens.interactions.txt.gz"), :fix => Proc.new {|l| l.gsub(/[\w ]+:/, "")})
      tsv.key_field = headers.shift
      tsv.fields    = headers

      tsv.to_s
    end, 'Reactome'
  ]
end
