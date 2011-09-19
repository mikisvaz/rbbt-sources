require 'rbbt-util'
module JoChem
  extend Resource
  self.subdir = "share/databases/JoChem"

  JoChem.claim JoChem.root, :rake, Rbbt.share.install.JoChem.Rakefile.find 
end
