require 'rbbt-util'
require 'rbbt/entity/gene'
require 'rbbt/tsv'
require 'rbbt/sources/organism'

module InterPro
  extend Resource
  self.subdir = "share/databases/InterPro"

  InterPro.claim InterPro.source.protein2ipr.find, :url, "ftp://ftp.ebi.ac.uk/pub/databases/interpro/protein2ipr.dat.gz"

  InterPro.claim InterPro.protein_domains.find, :proc do
    organism = "Hsa"
    uniprot_colum = TSV::Parser.new(Organism.protein_identifiers(organism).open).all_fields.index("UniProt/SwissProt Accession")
    uniprots = CMD.cmd("grep -v  '^#'|cut -f #{uniprot_colum+1}", :in => Organism.protein_identifiers(organism).open).read.split("\n").collect{|l| l.split("|")}.flatten.uniq.reject{|l| l.empty?}
   
    tsv = nil
    TmpFile.with_file(uniprots * "\n") do |tmpfile|
        tsv = TSV.open(CMD.cmd("cut -f 1,2,5,6 | sort -u |grep -w -f #{ tmpfile }", :in => InterPro.source.protein2ipr.open, :pipe => true), :merge => true, :type => :double)
    end
 
    tsv.key_field = "UniProt/SwissProt Accession"
    tsv.fields = ["InterPro ID", "Domain Start AA", "Domain End AA"]
    tsv.to_s
  end

  InterPro.claim InterPro.domain_names.find, :proc do
    #tsv = InterPro.source.protein2ipr.tsv :key_field => 1, :fields => [2], :type => :single
    tsv = TSV.open(CMD.cmd("cut -f 2,3 | sort -u", :in => InterPro.source.protein2ipr.open, :pipe => true), :merge => true, :type => :single)
 
    tsv.key_field = "InterPro ID"
    tsv.fields = ["Domain Name"]
    tsv.to_s
  end

  def self.name_index
    @@name_index ||= InterPro.domain_names.tsv(:persist => true)
  end

  def self.gene_index
    @@gene_index ||= InterPro.protein_domains.tsv(:persist => true, :key_field => "InterPro ID", :fields => ["UniProt/SwissProt Accession"], :type => :flat, :merge => true)
  end

  def self.domain_index
    @@domain_index ||= InterPro.protein_domains.tsv(:persist => true, :key_field => "UniProt/SwissProt Accession", :fields => ["InterPro ID"], :merge => true)
  end

  def self.domain_position_index
    @@domain_position_index ||= InterPro.protein_domains.tsv(:persist => true, :key_field => "UniProt/SwissProt Accession", :fields => ["InterPro ID", "Domain Start AA", "Domain End AA"], :type => :double, :merge => true)
  end

  def self.ens2uniprot(organism)
    @@ens2uniprot_index ||= {}
    @@ens2uniprot_index[organism] ||= Organism.protein_identifiers(organism).tsv(:persist => true, :fields => ["UniProt/SwissProt Accession"], :key_field => "Ensembl Protein ID", :type => :double, :merge => true)
  end

end

if defined? Entity 
  module InterProDomain
    extend Entity
    self.format = "InterPro ID"

    self.annotation :organism
    property :description => :array2single do
      InterPro.name_index.values_at *self
    end

    property :name => :array2single do
      InterPro.name_index.values_at *self
    end

    property :genes => :array2single do
      InterPro.gene_index.values_at(*self).
        collect{|genes| genes = genes.uniq;  genes.organism = organism if genes.respond_to? :organism; genes }
    end
  end

  if defined? Protein and Entity === Protein
    module Protein
      property :interpro_domains => :array2single do
        self.collect do |protein|
          uniprot = (InterPro.ens2uniprot(protein.organism)[protein] || []).flatten
          uniprot.empty? ? nil : 
            InterPro.domain_index.values_at(*uniprot).compact.flatten.  each{|pth| pth.organism = organism if pth.respond_to? :organism }.uniq.tap{|o| InterProDomain.setup(o, organism)}
        end
      end

      property :interpro_domain_positions => :array2single do
        self.collect do |protein|
          if protein.nil?
            []
          else
            uniprot = (InterPro.ens2uniprot(protein.organism)[protein] || []).flatten
            uniprot.empty? ? nil : 
              InterPro.domain_position_index.values_at(*uniprot).compact.flatten(1)
          end
        end
      end
    end
  end
end
