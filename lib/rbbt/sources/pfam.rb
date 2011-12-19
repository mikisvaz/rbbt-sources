require 'rbbt'
require 'rbbt/tsv'
require 'rbbt/resource'

module Pfam
  extend Resource
  self.subdir = "share/databases/Pfam"

  Pfam.claim Pfam.domains, :proc  do
    url = "ftp://ftp.sanger.ac.uk/pub/databases/Pfam/current_release/Pfam-A.clans.tsv.gz"
    tsv = TSV.open(Open.open(url), :key_field => "Pfam Domain ID", :fields => ["Pfam Clan ID", "Code Name", "Name", "Description"])
    tsv.to_s
  end

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
