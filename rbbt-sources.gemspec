# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: rbbt-sources 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rbbt-sources".freeze
  s.version = "3.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Miguel Vazquez".freeze]
  s.date = "2022-06-21"
  s.description = "Data sources like PubMed, Entrez Gene, or Gene Ontology".freeze
  s.email = "miguel.vazquez@fdi.ucm.es".freeze
  s.extra_rdoc_files = [
    "LICENSE"
  ]
  s.files = [
    "LICENSE",
    "etc/allowed_biomart_archives",
    "etc/biomart/missing_in_archive",
    "etc/build_organism",
    "etc/organisms",
    "etc/xena_hubs",
    "lib/rbbt/sources/CASCADE.rb",
    "lib/rbbt/sources/COREAD_phospho_proteome.rb",
    "lib/rbbt/sources/COSTART.rb",
    "lib/rbbt/sources/CTCAE.rb",
    "lib/rbbt/sources/GTRD.rb",
    "lib/rbbt/sources/HPRD.rb",
    "lib/rbbt/sources/MCLP.rb",
    "lib/rbbt/sources/MSigDB.rb",
    "lib/rbbt/sources/NCI.rb",
    "lib/rbbt/sources/PRO.rb",
    "lib/rbbt/sources/PSI_MI.rb",
    "lib/rbbt/sources/STITCH.rb",
    "lib/rbbt/sources/Xena.rb",
    "lib/rbbt/sources/array_express.rb",
    "lib/rbbt/sources/barcode.rb",
    "lib/rbbt/sources/bibtex.rb",
    "lib/rbbt/sources/biomart.rb",
    "lib/rbbt/sources/cancer_genome_interpreter.rb",
    "lib/rbbt/sources/cath.rb",
    "lib/rbbt/sources/clinvar.rb",
    "lib/rbbt/sources/corum.rb",
    "lib/rbbt/sources/ensembl.rb",
    "lib/rbbt/sources/ensembl_ftp.rb",
    "lib/rbbt/sources/entrez.rb",
    "lib/rbbt/sources/go.rb",
    "lib/rbbt/sources/gscholar.rb",
    "lib/rbbt/sources/intogen.rb",
    "lib/rbbt/sources/jochem.rb",
    "lib/rbbt/sources/kegg.rb",
    "lib/rbbt/sources/matador.rb",
    "lib/rbbt/sources/oncodrive_role.rb",
    "lib/rbbt/sources/oreganno.rb",
    "lib/rbbt/sources/organism.rb",
    "lib/rbbt/sources/pfam.rb",
    "lib/rbbt/sources/pharmagkb.rb",
    "lib/rbbt/sources/phospho_ELM.rb",
    "lib/rbbt/sources/phospho_site_plus.rb",
    "lib/rbbt/sources/pina.rb",
    "lib/rbbt/sources/polysearch.rb",
    "lib/rbbt/sources/pubmed.rb",
    "lib/rbbt/sources/reactome.rb",
    "lib/rbbt/sources/signor.rb",
    "lib/rbbt/sources/stitch.rb",
    "lib/rbbt/sources/string.rb",
    "lib/rbbt/sources/synapse.rb",
    "lib/rbbt/sources/tfacts.rb",
    "lib/rbbt/sources/uniprot.rb",
    "lib/rbbt/sources/wgEncodeBroadHmm.rb",
    "share/Ensembl/release_dates",
    "share/install/Genomes1000/Rakefile",
    "share/install/JoChem/Rakefile",
    "share/install/KEGG/Rakefile",
    "share/install/Matador/Rakefile",
    "share/install/NCI/Rakefile",
    "share/install/Organism/Hsa/Rakefile",
    "share/install/Organism/Mmu/Rakefile",
    "share/install/Organism/Rno/Rakefile",
    "share/install/Organism/Sce/Rakefile",
    "share/install/Organism/organism_helpers.rb",
    "share/install/PharmaGKB/Rakefile",
    "share/install/Pina/Rakefile",
    "share/install/STITCH/Rakefile",
    "share/install/STRING/Rakefile",
    "share/install/lib/helpers.rb",
    "share/install/lib/rake_helper.rb"
  ]
  s.homepage = "http://github.com/mikisvaz/rbbt-sources".freeze
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Data sources for the Ruby Bioinformatics Toolkit (rbbt)".freeze
  s.test_files = ["test/rbbt/sources/test_go.rb".freeze, "test/rbbt/sources/test_pubmed.rb".freeze, "test/rbbt/sources/test_pina.rb".freeze, "test/rbbt/sources/test_pharmagkb.rb".freeze, "test/rbbt/sources/test_organism.rb".freeze, "test/rbbt/sources/test_synapse.rb".freeze, "test/rbbt/sources/test_entrez.rb".freeze, "test/rbbt/sources/test_stitch.rb".freeze, "test/rbbt/sources/test_biomart.rb".freeze, "test/rbbt/sources/test_HPRD.rb".freeze, "test/rbbt/sources/test_string.rb".freeze, "test/rbbt/sources/test_kegg.rb".freeze, "test/rbbt/sources/test_tfacts.rb".freeze, "test/rbbt/sources/test_matador.rb".freeze, "test/rbbt/sources/test_gscholar.rb".freeze, "test/test_helper.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rbbt-util>.freeze, [">= 4.0.0"])
    s.add_runtime_dependency(%q<mechanize>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<bio>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rbbt-util>.freeze, [">= 4.0.0"])
    s.add_dependency(%q<mechanize>.freeze, [">= 0"])
    s.add_dependency(%q<nokogiri>.freeze, [">= 0"])
    s.add_dependency(%q<bio>.freeze, [">= 0"])
  end
end

