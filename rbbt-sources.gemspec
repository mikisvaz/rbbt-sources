# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rbbt-sources"
  s.version = "2.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Miguel Vazquez"]
  s.date = "2013-10-21"
  s.description = "Data sources like PubMed, Entrez Gene, or Gene Ontology"
  s.email = "miguel.vazquez@fdi.ucm.es"
  s.files = [
    "etc/biomart/missing_in_archive",
    "lib/rbbt/sources/COSMIC.rb",
    "lib/rbbt/sources/COSTART.rb",
    "lib/rbbt/sources/CTCAE.rb",
    "lib/rbbt/sources/HPRD.rb",
    "lib/rbbt/sources/InterPro.rb",
    "lib/rbbt/sources/NCI.rb",
    "lib/rbbt/sources/PSI_MI.rb",
    "lib/rbbt/sources/STITCH.rb",
    "lib/rbbt/sources/barcode.rb",
    "lib/rbbt/sources/bibtex.rb",
    "lib/rbbt/sources/biomart.rb",
    "lib/rbbt/sources/cath.rb",
    "lib/rbbt/sources/dbSNP.rb",
    "lib/rbbt/sources/ensembl.rb",
    "lib/rbbt/sources/ensembl_ftp.rb",
    "lib/rbbt/sources/entrez.rb",
    "lib/rbbt/sources/genomes1000.rb",
    "lib/rbbt/sources/go.rb",
    "lib/rbbt/sources/gscholar.rb",
    "lib/rbbt/sources/jochem.rb",
    "lib/rbbt/sources/organism.rb",
    "lib/rbbt/sources/pfam.rb",
    "lib/rbbt/sources/polysearch.rb",
    "lib/rbbt/sources/pubmed.rb",
    "lib/rbbt/sources/reactome.rb",
    "lib/rbbt/sources/tfacts.rb",
    "lib/rbbt/sources/uniprot.rb",
    "lib/rbbt/sources/wgEncodeBroadHmm.rb",
    "share/Ensembl/release_dates",
    "share/install/Genomes1000/Rakefile",
    "share/install/JoChem/Rakefile",
    "share/install/NCI/Rakefile",
    "share/install/Organism/Hsa/Rakefile",
    "share/install/Organism/Mmu/Rakefile",
    "share/install/Organism/Rno/Rakefile",
    "share/install/Organism/Sce/Rakefile",
    "share/install/Organism/organism_helpers.rb",
    "share/install/STITCH/Rakefile",
    "share/install/lib/helpers.rb"
  ]
  s.homepage = "http://github.com/mikisvaz/rbbt-sources"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "Data sources for the Ruby Bioinformatics Toolkit (rbbt)"
  s.test_files = ["test/rbbt/sources/test_go.rb", "test/rbbt/sources/test_entrez.rb", "test/rbbt/sources/test_biomart.rb", "test/rbbt/sources/test_gscholar.rb", "test/rbbt/sources/test_organism.rb", "test/rbbt/sources/test_pubmed.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rbbt-util>, [">= 4.0.0"])
      s.add_runtime_dependency(%q<rbbt-text>, [">= 0"])
      s.add_runtime_dependency(%q<libxml-ruby>, [">= 0"])
      s.add_runtime_dependency(%q<bio>, [">= 0"])
      s.add_runtime_dependency(%q<mechanize>, [">= 0"])
    else
      s.add_dependency(%q<rbbt-util>, [">= 4.0.0"])
      s.add_dependency(%q<rbbt-text>, [">= 0"])
      s.add_dependency(%q<libxml-ruby>, [">= 0"])
      s.add_dependency(%q<bio>, [">= 0"])
      s.add_dependency(%q<mechanize>, [">= 0"])
    end
  else
    s.add_dependency(%q<rbbt-util>, [">= 4.0.0"])
    s.add_dependency(%q<rbbt-text>, [">= 0"])
    s.add_dependency(%q<libxml-ruby>, [">= 0"])
    s.add_dependency(%q<bio>, [">= 0"])
    s.add_dependency(%q<mechanize>, [">= 0"])
  end
end

