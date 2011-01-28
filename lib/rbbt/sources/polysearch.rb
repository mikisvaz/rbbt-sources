require 'rbbt'

module Polysearch
  Rbbt.claim "organ" ,'http://wishart.biology.ualberta.ca/polysearch/include/organ_ID.txt', 'Polysearch'
  Rbbt.claim "tissue" ,'http://wishart.biology.ualberta.ca/polysearch/include/tissue_ID.txt', 'Polysearch'
  Rbbt.claim "location" ,'http://wishart.biology.ualberta.ca/polysearch/include/subcellular_localization_ID.txt', 'Polysearch'
  Rbbt.claim "disease" ,'http://wishart.biology.ualberta.ca/polysearch/include/disease_IDlist.txt', 'Polysearch'
  Rbbt.claim "drug" ,'http://wishart.biology.ualberta.ca/polysearch/include/drugnames.txt', 'Polysearch'
end
  
