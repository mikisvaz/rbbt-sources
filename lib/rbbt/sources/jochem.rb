require 'rbbt-util'
module JoChem
  Rbbt.claim Rbbt.share.databases.JoChem, :rake, Rbbt.share.install.JoChem.Rakefile.find 
end
