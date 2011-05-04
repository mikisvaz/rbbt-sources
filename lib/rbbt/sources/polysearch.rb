require 'rbbt'

module Polysearch
  Rbbt.share.databases.Polysearch.organ.define_as_url 'http://wishart.biology.ualberta.ca/polysearch/include/organ_ID.txt'
  Rbbt.share.databases.Polysearch.tissue.define_as_url 'http://wishart.biology.ualberta.ca/polysearch/include/tissue_ID.txt'
  Rbbt.share.databases.Polysearch.location.define_as_url 'http://wishart.biology.ualberta.ca/polysearch/include/subcellular_localization_ID.txt'
  Rbbt.share.databases.Polysearch.disease.define_as_url 'http://wishart.biology.ualberta.ca/polysearch/include/disease_IDlist.txt'
  Rbbt.share.databases.Polysearch.drug.define_as_url 'http://wishart.biology.ualberta.ca/polysearch/include/drugnames.txt'
end
  
