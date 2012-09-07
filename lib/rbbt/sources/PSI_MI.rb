require 'rbbt'
require 'rbbt/resource'
require 'rbbt/tsv'

module PSI_MI
  extend Resource
  self.subdir = Rbbt.share.databases.PSI_MI

  URL="http://psidev.cvs.sourceforge.net/viewvc/psidev/psi/mi/rel25/data/psi-mi25.obo"

  PSI_MI.claim PSI_MI.identifiers, :proc do
    tsv = TSV.setup({}, :type => :list, :key_field => "PSI-MI Term", :fields => ["Name", "Description"])
    Open.open(URL).read.split("[Term]").each do |chunk|
      id = chunk.scan(/id: ([^\n]*)/)[0]
      name = chunk.scan(/name: ([^\n]*)/)[0]
      description = chunk.scan(/def: "([^\n]*)"/)[0]
      tsv[id] = [name, description]
    end
    tsv.to_s
  end
end


if defined? Entity 
  require 'rbbt/entity/gene'
  require 'rbbt/entity/interactor'
  require 'rbbt/sources/PSI_MI'

  module PSI_MITerm
    extend Entity

    self.format = "PSI-MI Term"

    property :name => :array2single do
      @@index ||= PSI_MI.identifiers.tsv(:persist => true, :fields => ["Name"], :type => :single)
      @@index.values_at(*self)
    end
    
  end
end

