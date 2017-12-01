require 'rbbt-util'
require 'rbbt/resource'

module Oreganno
  extend Resource
  self.subdir = 'share/databases/Oreganno'

  def self.organism(org="Hsa")
    require 'rbbt/sources/organism'
    Organism.default_code(org)
  end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib


  Oreganno.claim Oreganno.data, :proc do 
    url = "http://www.oreganno.org/dump/ORegAnno_Combined_2016.01.19.tsv"
    TSV.open(url, :header_hash => '', :type => :list).to_s
  end

  Oreganno.claim Oreganno.tf_tg, :proc do
    dumper = TSV::Dumper.new :key_field => "Transcription Factor (Associated Gene Name)", :fields => ["Target Gene (Associated Gene Name)"], :type => :flat, :namespace => Oreganno.organism
    dumper.init
    TSV.traverse Oreganno.data, :type => :array, :into => dumper, :bar => true do |line|
      parts = line.split("\t")
      next unless parts[1] == "Homo sapiens"
      tf = parts[4]
      tg = parts[7]
      next if tf == "N/A" or tg == "N/A"
      [tf, [tg]]
    end
    TSV.collapse_stream dumper
  end
end

iif Oreganno.tf_tg.produce(true).find if __FILE__ == $0

