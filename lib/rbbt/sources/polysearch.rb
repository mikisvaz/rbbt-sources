require 'rbbt'

module Polysearch
  Rbbt.share.Polysearch.organ.define_as_url 'http://wishart.biology.ualberta.ca/polysearch/include/organ_ID.txt'
  Rbbt.share.Polysearch.tissue.define_as_url 'http://wishart.biology.ualberta.ca/polysearch/include/tissue_ID.txt'
  Rbbt.share.Polysearch.location.define_as_url 'http://wishart.biology.ualberta.ca/polysearch/include/subcellular_localization_ID.txt'
  Rbbt.share.Polysearch.disease.define_as_url 'http://wishart.biology.ualberta.ca/polysearch/include/disease_IDlist.txt'
  Rbbt.share.Polysearch.drug.define_as_url 'http://wishart.biology.ualberta.ca/polysearch/include/drugnames.txt'
end
  
