require 'rbbt-util'
require 'rbbt/resource'

module PhosphoSitePlus
  extend Resource
  self.subdir = 'share/databases/PhosphoSitePlus'

  def self.organism(org="Hsa")
    require 'rbbt/sources/organism'
    Organism.default_code(org)
  end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib
  
  #self.search_paths = {}
  #self.search_paths[:default] = :lib



  ALL_FILES = %w(Acetylation_site_dataset.gz Disease-associated_sites.gz
Kinase_Substrate_Dataset.gz Methylation_site_dataset.gz
O-GalNAc_site_dataset.gz O-GlcNAc_site_dataset.gz
Phosphorylation_site_dataset.gz Phosphosite_PTM_seq.fasta.gz
Phosphosite_seq.fasta.gz Regulatory_sites.gz Sumoylation_site_dataset.gz
Ubiquitination_site_dataset.gz)
  
  ALL_FILES.each do |file|
    PhosphoSitePlus.claim PhosphoSitePlus[".source"][file], :proc do |f|
      raise "Place #{file} from http://www.phosphosite.org/ at #{f}. Please consult license."
    end
  end

  PhosphoSitePlus.claim PhosphoSitePlus.kinase_substrate, :proc do 
    PhosphoSitePlus[".source/Kinase_Substrate_Dataset.gz"].produce
  end
end

iif PhosphoSitePlus.data.produce.find if __FILE__ == $0
