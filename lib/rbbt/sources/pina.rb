require 'rbbt-util'

module Pina
  extend Resource
  self.subdir = "share/databases/pina"

  Pina.claim Pina.protein_protein, :proc do
    require 'rbbt/sources/organism'

    url = "http://cbg.garvan.unsw.edu.au/pina/download/Homo%20sapiens-20121210.txt"

    dumper = TSV::Dumper.new :type => :list, :type => :double,
      :key_field => 'UniProt/SwissProt Accession', :namespace => Organism.default_code("Hsa"), 
      :fields => ['Interactor UniProt/SwissProt Accession', 'Method', 'Publication'] 


    dumper.init

    TSV.traverse Open.open(url), :type => :array, :into => dumper do |line|
      next if line =~  /Publication/

      parts = line.split("\t")
      uni1, uni2 = parts.values_at(0,1).collect{|v| v.partition(":").last}

      mi = parts[6].split("|").collect{|v| v.sub(/\(.*/,'').strip }

      pubmed = parts[8].split("|").collect{|v| v.partition(":").last}

      mi, pubmed = Misc.zip_fields(mi.zip(pubmed).uniq)

      [uni1, [[uni2], [mi * ";;"], [pubmed * ";;"]]]
    end

    Misc.collapse_stream(Misc.sort_stream(dumper.stream))
  end
end

if defined? Entity and defined? Gene and Entity === Gene
  require 'rbbt/entity/interactor'
  require 'rbbt/sources/PSI_MI'

  module Gene
    property :pina_interactors => :array2single do 
      ens2uniprot = Organism.identifiers(organism).tsv :key_field => "Ensembl Gene ID", :fields => ["UniProt/SwissProt Accession"], :type => :flat, :persist => true, :unnamed => true
      pina        = Pina.protein_protein.tsv(:persist => true, :fields => ["Interactor UniProt/SwissProt Accession", "Method", "Publication"], :type => :double, :merge => true, :unnamed => true)

      int = self.ensembl.collect do |ens|
        uniprot = ens2uniprot[ens]
        list = pina.values_at(*uniprot).compact.collect do |v|
          Misc.zip_fields(v).collect do |o, method, articles|
            Interactor.setup(o, PSI_MITerm.setup(method.split(";;")), PMID.setup(articles.split(";;")))
          end
        end.flatten.uniq
        Gene.setup(list, "UniProt/SwissProt Accession", organism).extend(AnnotatedArray)
      end

      Gene.setup(int, "UniProt/SwissProt Accession", organism).extend(AnnotatedArray)
    end
  end
end
