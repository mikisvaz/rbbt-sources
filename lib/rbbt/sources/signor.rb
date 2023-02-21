require 'rbbt-util'
require 'rbbt/resource'
require 'rbbt/sources/uniprot'

module Signor
  extend Resource
  self.subdir = 'share/databases/Signor'

  def self.organism(org="Hsa")
    require 'rbbt/sources/organism'
    Organism.default_code(org)
  end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib

  Signor.claim Signor[".source/all.csv"], :proc do |file|
    raise "Download all human data in CSV format from 'http://signor.uniroma2.it/downloads.php#all_download' and place in #{file}"
  end
  
  Signor.claim Signor.data, :proc do
    Signor[".source/all.csv"].tsv :header_hash => '', :merge => true, :zipped => true
  end

  Signor.claim Signor.protein_protein, :proc do 
    parser = TSV::Parser.new Signor.data
    fields = parser.fields
    dumper = TSV::Dumper.new :key_field => "Source (UniProt/SwissProt Accession)", :fields => ["Target (UniProt/SwissProt Accession)", "Effect", "Mechanism", "Residue"], :type => :double, :organism => Signor.organism
    dumper.init
    TSV.traverse parser, :into => dumper do |k,values|
      info = {}
      fields.zip(values).each do |field, value|
        info[field] = value
      end
      next unless info["TYPEA"].first == "protein"
      unia = info["IDA"].first

      res = []
      res.extend MultipleResult

      info["TYPEB"].zip(info["IDB"]).zip(info["EFFECT"]).zip(info["MECHANISM"]).zip(info["RESIDUE"]).each do |v|
        typeb,idb,eff,mech,resi = v.flatten
        next unless typeb == "protein"
        res << [unia, [idb, eff, mech,resi]]
      end

      res
    end

    Misc.collapse_stream dumper.stream
  end

  Signor.claim Signor.tf_tg, :proc do 
    require 'rbbt/sources/organism'

    organism = Organism.default_code("Hsa")
    #uni2name = Organism.identifiers(organism).index :target => "Associated Gene Name", :fields => ["UniProt/SwissProt Accession"], :persist => true
    uni2name = UniProt.identifiers.Hsa.index :target => "Associated Gene Name", :fields => ["UniProt/SwissProt Accession"], :persist => true

    parser = TSV::Parser.new Signor.data
    fields = parser.fields
    dumper = TSV::Dumper.new :key_field => "Source (UniProt/SwissProt Accession)", :fields => ["Target (Associated Gene Name)", "Effect", "Sign", "PMID"], :type => :double, :merge => true, :organism => Signor.organism
    dumper.init
    TSV.traverse parser, :into => dumper do |k,values|
      info = {}
      fields.zip(values).each do |field, value|
        info[field] = value
      end
      next unless info["TYPEA"].first == "protein"
      unia = info["IDA"].first

      res = []
      res.extend MultipleResult

      info["TYPEB"].zip(info["ENTITYB"]).zip(info["IDB"]).zip(info["EFFECT"]).zip(info["MECHANISM"]).zip(info["PMID"]).each do |v|
        typeb,nameb,idb,eff,mech,pmid = v.flatten
        
        next unless typeb == "protein"
        next unless mech == "transcriptional regulation"
        nameb ||= uni2name[idb]
        next if nameb.nil?
        sign = "Unknown"
        sign = "UP" if eff.include? 'up-regulates'
        sign = "DOWN" if eff.include? 'down-regulates'
        res << [unia, [nameb, eff, sign, pmid]]
      end

      res
    end

    Misc.collapse_stream dumper.stream
  end

  Signor.claim Signor.phospho_sites, :proc do

    dumper = TSV::Dumper.new :key_field => "Phosphosite", :fields => ["Effect"], :type => :flat, :organism => Signor.organism
    dumper.init

    TSV.traverse Signor.protein_protein, :into => dumper, :bar => true do |source, values|
      res = []
      res.extend MultipleResult
      Misc.zip_fields(values).each do |target, effect, mechanism, residue|
        kinase = case mechanism
                 when "phosphorylation" 
                   true
                 when "dephosphorylation" 
                   false
                 else
                   next
                 end
        next if residue.nil? or residue.empty?
        site = [target, residue] * ":"
        positive = effect.include? "up-regulates"

        activates = kinase && positive || (!kinase && !positive)

        res << [site, activates ? "Activates" : "Deactivates"]
      end
      res
    end

    TSV.collapse_stream(dumper)
  end
end

if __FILE__ == $0
  Log.severity = 0
  data = Signor.tf_tg.produce(true).find
  Log.tsv data
  #iif Signor.tf_tg.produce.find
end

