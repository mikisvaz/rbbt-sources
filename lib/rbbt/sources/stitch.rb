require 'rbbt/resource'
require 'rbbt/sources/organism'

module STITCH
  extend Resource
  self.subdir = "share/databases/STITCH"

  STITCH.claim STITCH.source.chemical_chemical, :url, "http://stitch.embl.de/download/chemical_chemical.links.detailed.v3.1.tsv.gz"
  STITCH.claim STITCH.source.protein_chemical, :url, "http://stitch.embl.de/download/protein_chemical.links.detailed.v3.1.tsv.gz"
  STITCH.claim STITCH.source.actions, :url, "http://stitch.embl.de/download/actions.v3.1.tsv.gz"
  STITCH.claim STITCH.source.aliases, :url, "http://stitch.embl.de/download/chemical.aliases.v3.1.tsv.gz"
  STITCH.claim STITCH.source.sources, :url, "http://stitch.embl.de/download/chemical.sources.v3.1.tsv.gz"

  Organism.installable_organisms.each do |organism|
    STITCH.claim STITCH.chemical_protein(organism), :proc do
      taxids = Organism.entrez_taxids(organism).read.split("\n")
      tsv = TSV.open(CMD.cmd("grep '\t\\(#{ taxids * '\|' }\\)\\.' | sed 's/\\(#{taxids * "|"}\\)\\.//'", :in =>  STITCH.source.protein_chemical.open, :pipe => true), :type => :double, :merge => true)
      tsv.key_field =  "Chemical CID"
      tsv.fields = ["Ensembl Gene ID", "experimental", "database", "textmining", "combined_score"]
      tsv.to_s
    end
  end


  STITCH.claim STITCH.identifiers, :proc do
    identifiers = {}
    fields = []
    first_line = true
    i = 0
    STITCH.source.aliases.read do |line|
      i += 1
      next if i == 1
      puts i
      cid, code, source = line.split("\t")

      pos = fields.index source
      if pos.nil?
        fields << source
        pos = fields.length - 1
      end
      identifiers[cid] ||= []
      identifiers[cid][pos] = code
    end

    TSV.setup(identifiers, :key_field => ["Chemical CID"], :fields => fields, :type => :double)

    identifiers.to_s
  end

  STITCH.claim STITCH.iupac, :proc do
    tsv = STITCH.source.aliases.tsv :type => :double, :merge => true, :grep => "IUPAC", :fields => [1]
    tsv.key_field = "Chemical CID"
    tsv.fields = ["IUPAC"]

    tsv.to_s
  end

  STITCH.claim STITCH.drug_bank, :proc do
    tsv = STITCH.source.aliases.tsv :type => :double, :merge => true, :grep => "DrugBank", :fields => [1]
    tsv.key_field = "Chemical CID"
    tsv.fields = ["DrugBank ID"]

    tsv.to_s
  end

end

if defined? Entity
  module Compound
    extend Entity

    self.annotation :format
    self.format = "Chemical CID"

    property :iupac => :array2single do
    end


  end
end

if __FILE__ ==      $0
  STITCH.source.chemical_chemical.produce
  STITCH.source.protein_chemical.produce
  STITCH.source.actions.produce
  STITCH.source.aliases.produce
  STITCH.source.sources.produce
  STITCH.chemical_protein("Hsa").produce
  STITCH.iupac.produce
  STITCH.drug_bank.produce
  STITCH.identifiers.produce
end
