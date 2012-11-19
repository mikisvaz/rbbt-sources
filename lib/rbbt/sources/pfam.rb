require 'rbbt'
require 'rbbt/tsv'
require 'rbbt/resource'
require 'rbbt/entity'
require 'rbbt/sources/InterPro'

module Pfam
  extend Resource
  self.subdir = "share/databases/Pfam"

  Pfam.claim Pfam.domains, :proc  do
    url = "ftp://ftp.sanger.ac.uk/pub/databases/Pfam/current_release/Pfam-A.clans.tsv.gz"
    tsv = TSV.open(Open.open(url), :key_field => "Pfam Domain ID", :fields => ["Pfam Clan ID", "Code Name", "Name", "Description"])
    tsv.to_s
  end

  NAMES_FILE = InterPro.pfam_names.find

  def self.name_index
    @name_index ||= TSV.open NAMES_FILE, :single, :unnamed => true
  end

  def self.name(id)
    name_index[id] || id
  end
end

module InterPro
  def self.pfam_index
    @@pfam_index ||= InterPro.pfam_equivalences.tsv(:persist => true, :key_field => "InterPro ID", :fields => ["Pfam Domain"])
  end
end

InterPro.claim InterPro.pfam_names.find, :proc do
  pfam_domains = Pfam.domains.read.split("\n").collect{|l| l.split("\t").first}.compact.flatten
  tsv = nil
  TmpFile.with_file(pfam_domains * "\n") do |tmpfile|
    tsv = TSV.open(CMD.cmd("cut -f 4,3 | sort -u |grep -w -f #{ tmpfile }", :in => InterPro.source.protein2ipr.open, :pipe => true), :key_field => 1, :fields => [0], :type => :single)
  end
  tsv.key_field = "InterPro ID"
  tsv.fields = ["Domain Name"]
  tsv.to_s
end

InterPro.claim InterPro.pfam_equivalences.find, :proc do
  pfam_domains = Pfam.domains.read.split("\n").collect{|l| l.split("\t").first}.compact.flatten
  tsv = nil
  TmpFile.with_file(pfam_domains * "\n") do |tmpfile|
    tsv = TSV.open(CMD.cmd("cut -f 2,4 | sort -u |grep -w -f #{ tmpfile }", :in => InterPro.source.protein2ipr.open, :pipe => true), :key_field => 0, :fields => [1], :type => :single)
  end
  tsv.key_field = "InterPro ID"
  tsv.fields = ["Pfam Domain"]
  tsv.to_s
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


  module InterProDomain
    property :pfam => :array2single do
      InterPro.pfam_index.values_at(*self).
        each{|domain| domain.organism = organism if domain.respond_to? :organism }
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


