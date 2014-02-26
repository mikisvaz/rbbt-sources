require 'rbbt'
require 'rbbt/resource'

module STITCH
  extend Resource
  self.subdir = "share/stitch"

  STITCH.claim STITCH.root, :rake, Rbbt.share.install.STITCH.Rakefile.find(:lib)
end
