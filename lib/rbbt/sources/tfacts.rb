require 'rbbt'
require 'rbbt/tsv'
require 'rbbt/resource'

module TFacts
  extend Resource
  self.subdir = "share/databases/TF"

  TFacts.claim TFacts.source["Catalogues.xls"], :url, "http://www.tfacts.org/TFactS-new/TFactS-v2/tfacts/data/Catalogues.xls"

  TFacts.claim TFacts.targets, :proc do
    require 'spreadsheet'
    book = Spreadsheet.open TFacts.source["Catalogues.xls"].produce.find
    sheet = book.worksheet 0

    tsv = TSV.setup({}, :key_field => "Associated Gene Name", :fields => ["Transcription Factor Associated Gene Name"], :namespace => "Hsa", :type => :flat)
    sheet.each do |row|
      target, tf = row.values_at 0, 1
      tsv[target] ||= []
      tsv[target] << tf
    end

    tsv.to_s
  end

  TFacts.claim TFacts.targets_signed, :proc do
    require 'spreadsheet'
    book = Spreadsheet.open TFacts.source["Catalogues.xls"].produce.find
    sheet = book.worksheet 0

    tsv = TSV.setup({}, :key_field => "Associated Gene Name", :fields => ["Transcription Factor Associated Gene Name", "Sign"], :namespace => "Hsa", :type => :double)
    sheet.each do |row|
      target, tf, sign = row.values_at 0, 1, 2
      tsv[target] ||= [[],[]]
      tsv[target][0] << tf
      tsv[target][1] << sign
    end

    tsv.to_s
  end

  TFacts.claim TFacts.regulators, :proc do
    TFacts.targets.tsv.reorder("Transcription Factor Associated Gene Name").to_s
  end

end

if defined? Entity and defined? Gene and Entity === Gene

  module Gene
    property :is_transcription_factor? => :array2single do
      tfs = TFacts.targets.keys
      self.name.collect{|gene| tfs.include? gene}
    end

    property :transcription_regulators => :array2single do
      Gene.setup(TFacts.regulators.tsv(:persist => true).values_at(*self.name), "Associated Gene Name", self.organism)
    end

    property :transcription_targets => :array2single do
      Gene.setup(TFacts.targets.tsv(:persist => true).values_at(*self.name), "Associated Gene Name", self.organism)
    end
  end
end
