require 'rbbt-util'
require 'rbbt/resource'

module PhosphoSitePlues
  extend Resource
  self.subdir = 'share/databases/PhosphoSitePlues'

  def self.organism(org="Hsa")
    require 'rbbt/sources/organism'
    Organism.default_code(org)
  end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib
  
  #self.search_paths = {}
  #self.search_paths[:default] = :lib



  ALL_FILES = %(Acetylation_site_dataset.gz Disease-associated_sites.gz
Kinase_Substrate_Dataset.gz Methylation_site_dataset.gz
O-GalNAc_site_dataset.gz O-GlcNAc_site_dataset.gz
Phosphorylation_site_dataset.gz Phosphosite_PTM_seq.fasta.gz
Phosphosite_seq.fasta.gz Regulatory_sites.gz Sumoylation_site_dataset.gz
Ubiquitination_site_dataset.gz)
  
  ALL_FILES.each do |file|
    PhosphoSitePlues.claim PhosphoSitePlues[".source"][file], :proc do |f|
      raise "Place #{file} from http://www.phosphosite.org/ at #{f}. Please consult license."
    end
  end

  PhosphoSitePlues.claim PhosphoSitePlues.kinase_substrate, :proc do 
    PhosphoSitePlues[".source/Kinase_Substrate_Dataset.gz"]
  end
end

iif PhosphoSitePlues.data.produce.find if __FILE__ == $0
