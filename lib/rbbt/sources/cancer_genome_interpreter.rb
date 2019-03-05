require 'rbbt-util'
require 'rbbt/resource'
require 'rbbt/sources/organism'

module CancerGenomeInterpreter
  extend Resource
  self.subdir = 'share/databases/CancerGenomeInterpreter'

  def self.organism(org="Hsa")
    Organism.default_code(org)
  end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib


  CancerGenomeInterpreter.claim CancerGenomeInterpreter['.source']["catalog_of_cancer_genes_latest.zip"], :url, "https://www.cancergenomeinterpreter.org/data/catalog_of_cancer_genes_latest.zip"

  CancerGenomeInterpreter.claim CancerGenomeInterpreter.mode_of_action, :proc do 
    TmpFile.with_file do |tmpdir|
      Open.mkdir tmpdir
      Misc.in_dir tmpdir do 
        `unzip '#{CancerGenomeInterpreter['.source']["catalog_of_cancer_genes_latest.zip"].produce.find}'`
        tsv = TSV.open('gene_MoA.tsv', :header_hash => '', :type => :single)
        tsv.key_field = "Associated Gene Name"
        tsv.namespace = CancerGenomeInterpreter.organism
        tsv.fields = ["Mode of Action"]
        tsv
      end
    end
  end

  CancerGenomeInterpreter.claim CancerGenomeInterpreter.mutation_and_CNA, :proc do 
    TmpFile.with_file do |tmpdir|
      Open.mkdir tmpdir
      Misc.in_dir tmpdir do 
        `unzip '#{CancerGenomeInterpreter['.source']["catalog_of_cancer_genes_latest.zip"].produce.find}'`
        tsv = TSV.open('cancer_genes_upon_mutations_or_CNAs.tsv', :header_hash => '', :type => :list)
        tsv.key_field = "Associated Gene Name"
        tsv.namespace = CancerGenomeInterpreter.organism
        tsv
      end
    end
  end

  CancerGenomeInterpreter.claim CancerGenomeInterpreter.translocations, :proc do 
    TmpFile.with_file do |tmpdir|
      Open.mkdir tmpdir
      Misc.in_dir tmpdir do 
        `unzip '#{CancerGenomeInterpreter['.source']["catalog_of_cancer_genes_latest.zip"].produce.find}'`
        tsv = TSV.open('cancer_genes_upon_trans.tsv', :header_hash => '', :type => :list)
        tsv.namespace = CancerGenomeInterpreter.organism
        tsv
      end
    end
  end
  
  CancerGenomeInterpreter.claim CancerGenomeInterpreter.acronyms, :proc do 
    TmpFile.with_file do |tmpdir|
      Open.mkdir tmpdir
      Misc.in_dir tmpdir do 
        `unzip '#{CancerGenomeInterpreter['.source']["catalog_of_cancer_genes_latest.zip"].produce.find}'`
        TSV.open('cancer_acronyms.tsv', :header_hash => '', :type => :single)
      end
    end
  end
end

iif CancerGenomeInterpreter.mode_of_action.produce.find if __FILE__ == $0
iif CancerGenomeInterpreter.mutation_and_CNA.produce.find if __FILE__ == $0
iif CancerGenomeInterpreter.translocations.produce.find if __FILE__ == $0
iif CancerGenomeInterpreter.acronyms.produce.find if __FILE__ == $0

