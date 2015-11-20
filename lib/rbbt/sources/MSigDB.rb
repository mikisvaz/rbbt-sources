require 'rbbt-util'
require 'rbbt/resource'
require 'rbbt/sources/organism'

module MSigDB
  extend Resource
  self.subdir = 'share/databases/MSigDB'

  def self.organism(org="Hsa")
    Organism.default_code(org)
  end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib

  MSigDB.claim MSigDB['.source/all_sets.zip'], :proc do |filename|
    raise "Download the 'ZIPed file set' from http://software.broadinstitute.org/gsea/downloads.jsp into #{filename}"
  end

  MSigDB.claim MSigDB.all_sets, :proc do |dirname|
    zip_file = MSigDB['.source/all_sets.zip'].produce.find
    TmpFile.with_dir do |tmpdir|
      Misc.unzip_in_dir(zip_file, tmpdir)
      Path.setup(tmpdir)
      tmpdir.glob('**/*symbols.gmt').each do |file|
        name_parts = File.basename(file).split(".")
        base_name = name_parts[0..-5] * "_"
        dumper = TSV::Dumper.new :key_field => "MSigDB Geneset ID", :fields => ["Associated Gene Name"], :namespace => MSigDB.organism, :type => :flat
        dumper.init
        io = TSV.traverse file, :type => :array, :into => dumper do |line|
          name, url, *genes = line.split("\t")
          [name, genes]
        end
        Open.write(dirname[base_name], io.stream)
      end
    end
  end
end

if defined? Entity

  module MSigDBGeneSet
    extend Entity
    self.format= "MSigDB Geneset ID"

    property :name => :single2array do
      self.downcase.gsub("_",' ')
    end

    property :genes => :single2array do
      @@pathway_genes ||= MSigDB.all_sets.msigdb.tsv :persist => true
      genes = @@pathway_genes[self]
      Gene.setup(genes, "Associated Gene Name", MSigDB.organism).ensembl
    end
  end
end

