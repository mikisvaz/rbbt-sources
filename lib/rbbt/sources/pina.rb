require 'phgx'

module Pina
  extend Resource
  self.pkgdir = "phgx"
  self.subdir = "share/pina"

  Pina.claim Pina.root, :rake, Rbbt.share.install.Pina.Rakefile.find(:lib)
end

if defined? Entity and defined? Gene and Entity === Gene
  require 'rbbt/entity/gene'
  require 'rbbt/entity/interactor'
  require 'rbbt/sources/PSI_MI'

  module Gene
    property :pina_interactors => :array2single do 
      ens2uniprot = Organism.identifiers(organism).tsv :key_field => "Ensembl Gene ID", :fields => ["UniProt/SwissProt Accession"], :type => :flat, :persist => true, :unnamed => true
      pina        = Pina.protein_protein.tsv(:persist => true, :fields => ["Interactor UniProt/SwissProt Accession", "Method", "PMID"], :type => :double, :merge => true, :unnamed => true)

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

