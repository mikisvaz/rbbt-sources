require 'rbbt'
require 'rbbt/resource'

module Matador
  extend Resource
  self.subdir = "share/databases/matador"

  Matador.claim Matador.root, :rake, Rbbt.share.install.Matador.Rakefile.find(:lib)
end
