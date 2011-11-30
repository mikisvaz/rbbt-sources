require 'rbbt'
require 'rbbt/tsv'

module Pfam
  NAMES_FILE = Rbbt.share.databases.InterPro.pfam_names.find

  def self.name_index
    @name_index ||= TSV.open NAMES_FILE, :single
  end

  def self.name(id)
    name_index[id]
  end
end

if defined? Entity
  module PfamDomain
    extend Entity
    self.format = "Pfam Domain"
    
    property :name => :array2single do
      self.collect{|id| Pfam.name(id)}
    end
  end
end
