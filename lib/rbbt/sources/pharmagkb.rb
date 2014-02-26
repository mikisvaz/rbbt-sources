require 'rbbt'
require 'rbbt/resource'

module PharmaGKB
  extend Resource
  self.subdir = "share/pharmagkb"

  PharmaGKB.claim PharmaGKB.root, :rake, Rbbt.share.install.PharmaGKB.Rakefile.find(:lib)
end
