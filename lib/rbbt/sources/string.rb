require 'phgx'

module STRING
  extend Resource
  self.pkgdir = "phgx"
  self.subdir = "share/string"

  STRING.claim STRING.root, :rake, Rbbt.share.install.STRING.Rakefile.find(:lib)
end

if defined? Entity and defined? Gene and Entity === Gene
  module Gene
    property :string_interactors => :array2single do |*args|
      threshold = args.first || 800
      string = STRING.protein_protein.tsv(:unnamed => true, :persist => true, :type => :double)
      all = self.ensembl.collect do |gene|
        interactors = gene.proteins.collect{|protein| Misc.zip_fields((string[protein] || [[],[]])).select{|i, score| score.to_i > threshold}.collect{|ints,s| ints}}.compact.flatten.uniq
        Protein.setup(interactors, "Ensembl Protein ID", organism).transcript.gene.compact.uniq
      end

      all.compact.first.annotate all if Annotated === all.compact.first 

      all
    end
  end
end

