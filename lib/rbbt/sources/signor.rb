require 'rbbt-util'
require 'rbbt/resource'

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
    sio = Signor[".source/all.csv"].open
    io_tmp = Misc.remove_quoted_new_line(sio)
    io = Misc.swap_quoted_character(io_tmp, ';', '--SEMICOLON--')
    
    tsv = TSV.open io, :header_hash => "", :sep => ";", :merge => true, :type => :double, :zipped => true, :monitor => true
    tsv.each do |k,values|
      clean_values = values.collect{|vs| vs.collect{|v| (v[0] == '"' and v[-1] = '"') ? v[1..-2] : v }.collect{|v| v.gsub("--SEMICOLON--", ';') } }

      values.replace clean_values
    end
    tsv
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
    uni2name = Organism.identifiers(organism).index :target => "Associated Gene Name", :fields => ["UniProt/SwissProt Accession"], :persist => true

    parser = TSV::Parser.new Signor.data
    fields = parser.fields
    dumper = TSV::Dumper.new :key_field => "Source (UniProt/SwissProt Accession)", :fields => ["Target (Associated Gene Name)", "Effect", "Sign", "PMID"], :type => :double, :organism => Signor.organism
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

      info["TYPEB"].zip(info["IDB"]).zip(info["EFFECT"]).zip(info["MECHANISM"]).zip(info["PMID"]).each do |v|
        typeb,idb,eff,mech,pmid = v.flatten
        
        next unless typeb == "protein"
        next unless mech == "transcriptional regulation"
        nameb = uni2name[idb]
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
end

iif Signor.tf_tg.produce(true).find if __FILE__ == $0

