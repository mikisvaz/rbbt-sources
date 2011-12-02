require 'rbbt-util'
module NCI
  extend Resource
  self.subdir = "share/databases/NCI"

  NCI.claim NCI.root.find, :rake, Rbbt.share.install.NCI.Rakefile.find(:lib)
end

if defined? Entity 

  module NCINaturePathways

    def self.name_index
      @name_index ||= NCI.nature_pathways.tsv(:persist => true, :key_field => "NCI Nature Pathway ID", :fields => ["Pathway Name"], :type => :single)
    end

    def self.gene_index
      @gene_index ||= NCI.nature_pathways.tsv(:persist => true, :key_field => "NCI Nature Pathway ID", :fields => ["UniProt/SwissProt Accession"], :type => :flat, :merge => true)
    end


    extend Entity
    self.format = "NCI Nature Pathway ID"

    property :name => :array2single do
      @name ||= NCINaturePathways.name_index.values_at *self
    end

    property :genes => :array2single do
      @genes ||= NCINaturePathways.gene_index.values_at *self
    end
  end

  module NCIReactomePathways
    extend Entity
    self.format = "NCI Reactome Pathway ID"

    def self.name_index
      @name_index ||= NCI.reactome_pathways.tsv(:persist => true, :key_field => "NCI Reactome Pathway ID", :fields => ["Pathway Name"], :type => :single)
    end

    def self.gene_index
      @gene_index ||= NCI.reactome_pathways.tsv(:persist => true, :key_field => "NCI Reactome Pathway ID", :fields => ["UniProt/SwissProt Accession"], :type => :flat, :merge => true)
    end

    property :name => :array2single do
      @name ||= NCIReactomePathways.name_index.values_at *self
    end

    property :genes => :array2single do
      @genes ||= NCIReactomePathways.gene_index.values_at *self
    end
  end

  module NCIBioCartaPathways
    extend Entity
    self.format = "NCI BioCarta Pathway ID"

    def self.name_index
      @name_index ||= NCI.biocarta_pathways.tsv(:persist => true, :key_field => "NCI BioCarta Pathway ID", :fields => ["Pathway Name"], :type => :single)
    end

    def self.gene_index
      @gene_index ||= NCI.biocarta_pathways.tsv(:persist => true, :key_field => "NCI BioCarta Pathway ID", :fields => ["Entrez Gene ID"], :type => :flat, :merge => true)
    end

    property :name => :array2single do
      @name ||= NCIBioCartaPathways.name_index.values_at *self
    end

    property :genes => :array2single do
      @genes ||= NCIBioCartaPathways.gene_index.values_at *self
    end
  end

  if defined? Gene and Entity === Gene
    module Gene
      property :nature_pathways => :array2single do
        @nature_pathways ||= NCI.nature_pathways.tsv(:persist => true, :key_field => "UniProt/SwissProt Accession", :fields => ["NCI Nature Pathway ID"], :type => :flat, :merge => true).values_at *self.to("UniProt/SwissProt Accession")
      end

      property :reactome_pathways => :array2single do
        @reactome_pathways ||= NCI.reactome_pathways.tsv(:persist => true, :key_field => "UniProt/SwissProt Accession", :fields => ["NCI Reactome Pathway ID"], :type => :flat, :merge => true).values_at *self.to("UniProt/SwissProt Accession")
      end
 
      property :biocarta_pathways => :array2single do
        @biocarta_pathways ||= NCI.biocarta_pathways.tsv(:persist => true, :key_field => "Entrez Gene ID", :fields => ["NCI BioCarta Pathway ID"], :type => :flat, :merge => true).values_at *self.entrez
      end
    end
  end
end
