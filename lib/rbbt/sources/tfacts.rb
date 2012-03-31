require 'rbbt'
require 'rbbt/resource'
require 'nokogiri'

module TFacts
  extend Resource
  self.subdir = "share/databases/TF"

  def self.targets_for_gene_unsigned(gene_name)
    doc = Nokogiri::HTML(Open.read("http://www.tfacts.org/source/tfsResultsns.php", :post => "TFS_ID=#{ gene_name }"))

    doc.css("td a").collect{|link| link.content.strip}
  end

  def self.targets_for_gene_signed(gene_name)
    doc = Nokogiri::HTML(Open.read("http://www.tfacts.org/source/tfsResults.php", :post => "TFS_ID=#{ gene_name }"))

    rows = doc.css("tr")
    rows.shift
    targets = {}
    rows.each{|row| gene, sign = row.css("td"); targets[gene.css("a").first.content.strip] = sign.content.strip}
    targets
  end

  def self.known_transcription_factors_signed
    Open.read("http://www.tfacts.org/source/tfs.php").scan(/OPTION VALUE=([^\s]+)/).flatten
  end

  def self.known_transcription_factors_unsigned
    Open.read("http://www.tfacts.org/source/tfsns.php").scan(/OPTION VALUE=([^\s]+)/).flatten
  end

  TFacts.claim TFacts.targets, :proc do
    tsv = Misc.process_to_hash(TFacts.known_transcription_factors_unsigned){|list| list.collect{|tf| TFacts.targets_for_gene_unsigned(tf)}}
    TSV.setup tsv, :key_field => "Associated Gene Name", :fields => ["Target Associated Gene Name"], :type => :flat, :unnamed => true
    tsv.to_s
  end

  TFacts.claim TFacts.regulators, :proc do
    TFacts.targets.tsv.reorder("Target Associated Gene Name").to_s
  end

  TFacts.claim TFacts.targets_signed, :proc do
    tsv = TSV.setup({}, :key_field => "Associated Gene Name", :fields => ["Target Associated Gene Name", "Target Sign"], :type => :double, :unnamed => true)
    Misc.process_to_hash(TFacts.known_transcription_factors_signed){|list| list.collect{|tf| TFacts.targets_for_gene_signed(tf)}}.each do |tf, targets|
      tsv[tf] = [targets.keys, targets.values]
    end
    tsv.to_s
  end
end

if defined? Entity and defined? Gene and Entity === Gene

  module Gene
    property :is_transcription_factor? => :array2single do
      tfs = TFacts.targets.keys
      self.name.collect{|gene| tfs.include? gene}
    end
    persist :_ary_is_transcription_factor?

    property :transcription_regulators => :array2single do
      Gene.setup(TFacts.regulators.tsv(:persist => true).values_at(*self.name), "Associated Gene Name", self.organism)
    end
    persist :_ary_transcription_regulators

    property :transcription_targets => :array2single do
      Gene.setup(TFacts.targets.tsv(:persist => true).values_at(*self.name), "Associated Gene Name", self.organism)
    end
    persist :_ary_transcription_targets
  end
end
