require 'rbbt'

module Polysearch
  Rbbt.add_datafiles "organ"      => ['Polysearch','http://wishart.biology.ualberta.ca/polysearch/include/organ_ID.txt']
  Rbbt.add_datafiles "tissue"     => ['Polysearch','http://wishart.biology.ualberta.ca/polysearch/include/tissue_ID.txt']
  Rbbt.add_datafiles "location"   => ['Polysearch','http://wishart.biology.ualberta.ca/polysearch/include/subcellular_localization_ID.txt']
  Rbbt.add_datafiles "disease"    => ['Polysearch','http://wishart.biology.ualberta.ca/polysearch/include/disease_IDlist.txt']
  Rbbt.add_datafiles "drug"       => ['Polysearch','http://wishart.biology.ualberta.ca/polysearch/include/drugnames.txt']
  Rbbt.add_datafiles "metabolite" => ['Polysearch','http://wishart.biology.ualberta.ca/polysearch/include/HMDBnames.txt']
end
  
