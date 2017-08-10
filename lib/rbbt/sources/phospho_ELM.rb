require 'rbbt-util'
require 'rbbt/resource'

module PhosphoELM
  extend Resource
  self.subdir = 'share/databases/PhosphoELM'

  def self.organism(org="Hsa")
    require 'rbbt/sources/organism'
    Organism.default_code(org)
  end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib

  PhosphoELM.claim PhosphoELM[".source/dump.tgz"], :proc do |file|
    raise "Place phosphoELM_all_latest.dump.tgz from http://phospho.elm.eu.org at #{file}. Please consult license."
  end

  PhosphoELM.claim PhosphoELM.data, :proc do 
    tgz = PhosphoELM[".source/dump.tgz"].produce.find

    organism = PhosphoELM.organism
    uni2ensp = Organism.identifiers(organism).tsv :key_field => "UniProt/SwissProt Accession", :fields => ["Ensembl Protein ID"], :type => :flat, :persist => true
    ensp2seq = Organism.protein_sequence(organism).tsv :persist => true

    dumper = TSV::Dumper.new(:key_field => "Phosphosite", :fields => ["Kinases", "Source", "PMID"], :type => :list)
    dumper.init
    TmpFile.with_file do |dir|
      Misc.in_dir dir do
        CMD.cmd("tar xvfz #{tgz}")
        f = Dir.glob("*.dump").first
        TSV.traverse Open.open(f), :type => :array, :into => dumper do |line|
          next unless line =~ /Homo sapiens/
          acc, sequence, position, code, pmids, kinases, source, species, entry_date = line.split("\t")
          ensps = uni2ensp[acc]
          Log.warn "No Ensembl Protein ID for #{acc}" if ensps.nil?
          next if ensps.nil?
          sequence << "*"
          good = ensps.select{|ensp| sequence == ensp2seq[ensp]}
          Log.warn "No sequence match for #{acc} - #{ensps*", "}" if good.empty?
          next if good.empty?
          res = []
          good.each do |ensp|
            phospho_site = [ensp,":", code, position] * ""
            res << [phospho_site, [kinases, source, pmids]]
          end
          res.extend MultipleResult

          res
        end
      end
    end
    dumper.stream
  end
end

iif PhosphoELM.data.produce(true).find if __FILE__ == $0

