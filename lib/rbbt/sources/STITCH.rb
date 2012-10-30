require 'rbbt/resource'
require 'rbbt/sources/organism'

module STITCH
  extend Resource
  self.subdir = "share/databases/STITCH"

  STITCH.claim STITCH.source.chemical_chemical.find, :url, "http://stitch.embl.de/download/chemical_chemical.links.detailed.v3.1.tsv.gz"
  STITCH.claim STITCH.source.protein_chemical.find, :url, "http://stitch.embl.de/download/protein_chemical.links.detailed.v3.1.tsv.gz"
  STITCH.claim STITCH.source.actions.find, :url, "http://stitch.embl.de/download/actions.v3.1.tsv.gz"
  STITCH.claim STITCH.source.aliases.find, :url, "http://stitch.embl.de/download/chemical.aliases.v3.1.tsv.gz"
  STITCH.claim STITCH.source.sources.find, :url, "http://stitch.embl.de/download/chemical.sources.v3.1.tsv.gz"

  Organism.instalable_organisms.each do |organism|
    STITCH.claim STITCH.chemical_protein(organism), :proc do
      taxids = Organism.entrez_taxids(organism).read.split("\n")
      tsv = TSV.open(CMD.cmd("grep '\t\\(#{ taxids * '\|' }\\)\\.' | sed 's/\\(#{taxids * "|"}\\)\\.//'", :in =>  STITCH.source.protein_chemical.open, :pipe => true), :type => :double, :merge => true)
      tsv.key_field =  "Chemical CID"
      tsv.fields = ["Ensembl Gene ID", "experimental", "database", "textmining", "combined_score"]
      tsv.to_s
    end
  end


  STITCH.claim STITCH.chemicals, :proc, "http://stitch.embl.de/download/actions.v3.1.tsv.gz"
end

if __FILE__ ==      $0
  STITCH.source.chemical_chemical.produce
  STITCH.source.protein_chemical.produce
  STITCH.source.actions.produce
  STITCH.source.aliases.produce
  STITCH.source.sources.produce
  STITCH.chemical_chemical("Hsa").produce
end
