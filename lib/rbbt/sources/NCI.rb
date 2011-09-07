require 'rbbt-util'
module NCI
  extend Resource
  self.subdir = "share/databases/NCI"

  NCI.claim NCI.root.find, :rake, Rbbt.share.install.NCI.Rakefile.find(:lib)
end
