require 'rbbt-util'
module JoChem
  Rbbt.share.databases.JoChem.define_as_rake Rbbt.share.install.JoChem.Rakefile.find 
end
