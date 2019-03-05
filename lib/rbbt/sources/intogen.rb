require 'rbbt-util'
require 'rbbt/resource'

module Intogen
  extend Resource
  self.subdir = 'share/databases/Intogen'

  #def self.organism(org="Hsa")
  #  Organism.default_code(org)
  #end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib


  Intogen.claim Intogen['.source']["intogen_driver_mutations_catalog.zip"], :proc do |filename|
    raise "Download the fila at 'https://www.intogen.org/downloads?file=/repository/downloads/intogen_driver_mutations_catalog-2016.5.zip' into '#{filename}'"
  end

  Intogen.claim Intogen.driver_mutations_catalog, :proc do |filaname|
    all_tsv = nil
    TmpFile.with_file do |tmpdir|
      Open.mkdir tmpdir
      Misc.in_dir tmpdir do 
        `unzip '#{Intogen['.source']["intogen_driver_mutations_catalog.zip"].produce.find}'`
        Dir.glob("./*/mutation_analysis.tsv").each do |file|
          cohort = File.basename(File.dirname(file))

          parser = TSV::Parser.new file, :header_hash => '', :type => :list
          if all_tsv.nil?
            all_tsv = TSV.setup({}, :key_field => 'Mutation ID', :fields => ["Sample", "Cohort", "Genomic Mutation"] + parser.fields, :type => :list) 
          end

          TSV.traverse parser, :into => all_tsv do |sample, values|
            chr, strand, pos, ref, alt, *rest = values
            mutation = [chr, pos, alt] * ":"
            id = [sample, mutation] * "_"
            [id, [sample, cohort, mutation] + values]
          end
        end
      end
    end
    all_tsv.to_s
  end
end

iif Intogen.driver_mutations_catalog.produce.find if __FILE__ == $0

