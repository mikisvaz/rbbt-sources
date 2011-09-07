require 'rbbt'

module Polysearch
  Rbbt.claim Rbbt.share.databases.Polysearch.organ, :url, 'http://wishart.biology.ualberta.ca/polysearch/include/organ_ID.txt'
  Rbbt.claim Rbbt.share.databases.Polysearch.tissue, :url, 'http://wishart.biology.ualberta.ca/polysearch/include/tissue_ID.txt'
  Rbbt.claim Rbbt.share.databases.Polysearch.location, :url, 'http://wishart.biology.ualberta.ca/polysearch/include/subcellular_localization_ID.txt'
  Rbbt.claim Rbbt.share.databases.Polysearch.disease, :url, 'http://wishart.biology.ualberta.ca/polysearch/include/disease_IDlist.txt'
  Rbbt.claim Rbbt.share.databases.Polysearch.drug, :url, 'http://wishart.biology.ualberta.ca/polysearch/include/drugnames.txt'
end
  
