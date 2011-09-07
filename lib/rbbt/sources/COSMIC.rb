require 'rbbt'
require 'rbbt/resource'
module COSMIC
  extend Resource
  self.subdir = "share/databases/COSMIC"

  COSMIC.claim COSMIC.Mutations, :proc do 
    url = "ftp://ftp.sanger.ac.uk/pub/CGP/cosmic/data_export/CosmicMutantExport_v54_120711.tsv"

    TSV.open(Open.open(url), :header_hash => "", :key_field => "Mutation GRCh37 genome position", :merge => true).to_s
  end
end

puts COSMIC.Mutations.produce
