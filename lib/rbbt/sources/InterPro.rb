require 'rbbt-util'
module InterPro
  extend Resource
  self.subdir = "share/databases/InterPro"

  InterPro.claim InterPro.root.find, :rake, Rbbt.share.install.InterPro.Rakefile.find(:lib)

  def self.tsv(*args)
    old_url = BioMart::BIOMART_URL
    begin
      BioMart::BIOMART_URL.replace "http://www.ebi.ac.uk/interpro/biomart/martservice?query="
      BioMart.tsv(*args)
    ensure
      BioMart::BIOMART_URL.replace old_url
    end
  end
end
