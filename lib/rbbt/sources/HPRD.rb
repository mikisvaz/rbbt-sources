require 'rbbt-util'
require 'rbbt/entity/gene'
require 'rbbt/tsv'
require 'rbbt/sources/organism'

module HPRD
  extend Resource
  self.subdir = "share/databases/HPRD"

  HPRD.claim HPRD["BINARY_PROTEIN_PROTEIN_INTERACTIONS.txt"], :proc do
    raise "File BINARY_PROTEIN_PROTEIN_INTERACTIONS.txt not found in '#{HPRD["BINARY_PROTEIN_PROTEIN_INTERACTIONS.txt"].find}', download manually from http://www.hprd.org/"
  end

  HPRD.claim HPRD.protein_protein, :proc do
    tsv = HPRD["BINARY_PROTEIN_PROTEIN_INTERACTIONS.txt"].tsv

    tsv.key_field = "Associated Gene Name 1"
    tsv.fields = ["HPRD id 1","RefSeq Protein ID 1","Associated Gene Name 2","HPRD id 2","RefSeq Protein ID 2", "Experiment type", "PMID"]
    tsv.namespace = "Hsa"

    tsv.to_s
  end
end  
