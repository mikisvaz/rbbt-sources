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
    name_index[id] || id
  end
end

if defined? Entity
  module PfamDomain
    extend Entity
    self.format = "Pfam Domain"
    self.format = "Pfam Domain ID"

    self.annotation :organism
    
    property :name => :array2single do
      self.collect{|id| Pfam.name(id)}
    end

    property :genes => :array2single do
      @genes ||= Organism.gene_pfam(organism).tsv(:key_field => "Pfam Domain", :fields => ["Ensembl Gene ID"], :persist => true, :merge => true, :type => :flat, :namespace => organism).values_at *self
    end
  end
  if defined? Gene and Entity === Gene
    module Gene
      INDEX_CACHE = {}

      property :pfam_domains => :array2single do
        index = INDEX_CACHE[organism] ||= Organism.gene_pfam(organism).tsv(:persist => true, :type => :flat, :fields => ["Pfam Domain"], :key_field => "Ensembl Gene ID", :namespace => organism)
        @pfam_domains ||= index.values_at *self.ensembl
      end
 
    end
  end
end
