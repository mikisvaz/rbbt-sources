require 'rbbt'
require 'rbbt/tsv'
require 'rbbt/resource'

module TFactS
  extend Resource
  self.subdir = "share/databases/TFactS"

  TFactS.claim TFactS[".source"]["Catalogues.xls"], :url, "http://www.tfacts.org/TFactS-new/TFactS-v2/tfacts/data/Catalogues.xls"

  TFactS.claim TFactS.targets, :proc do
    require 'spreadsheet'
    book = Spreadsheet.open TFactS[".source"]["Catalogues.xls"].produce.find
    sheet = book.worksheet 0

    tsv = TSV.setup({}, :key_field => "Target Gene (Associated Gene Name)", :fields => ["Transcription Factor (Associated Gene Name)"], :namespace => "Hsa", :type => :flat)
    sheet.each do |row|
      target, tf = row.values_at 0, 1
      next if tf =~ /OFFICIAL_/
      tsv[target] ||= []
      tsv[target] << tf
    end

    tsv.to_s
  end

  TFactS.claim TFactS.targets_signed, :proc do
    require 'spreadsheet'
    book = Spreadsheet.open TFactS[".source"]["Catalogues.xls"].produce.find
    sheet = book.worksheet 1

    tsv = TSV.setup({}, :key_field => "Target Gene (Associated Gene Name)", :fields => ["Transcription Factor (Associated Gene Name)", "Sign", "PMID"], :namespace => "Hsa", :type => :double)
    sheet.each do |row|
      target, tf, sign, pmid = row.values_at(0, 1, 2, 5).collect{|e| e.to_s.gsub("\n", " ") }
      pmid = pmid.split(";").select{|p| p =~ /^\d{5,}$/ }
      next if tf =~ /OFFICIAL_/
      tsv[target] ||= [[],[],[]]
      tsv[target][0] << tf
      tsv[target][1] << sign
      tsv[target][2] << pmid * ";"
    end

    tsv.to_s
  end

  TFactS.claim TFactS.regulators, :proc do
    TFactS.targets.tsv.reorder("Transcription Factor (Associated Gene Name)").to_s
  end

  TFactS.claim TFactS.tf_tg, :proc do
    require 'spreadsheet'
    book = Spreadsheet.open TFactS[".source"]["Catalogues.xls"].produce.find

    tsv = TSV.setup({}, :key_field => "Transcription Factor (Associated Gene Name)", :fields => ["Target Gene (Associated Gene Name)", "Sign", "Species", "Source", "PMID"], :namespace => "Hsa", :type => :double)

    sheet = book.worksheet 1
    sheet.each do |row|
      target, tf, sign, source, species, pmids = row.values_at(0, 1, 2, 3, 4, 5).collect{|v| v.to_s.gsub(/\s/, ' ') }
      pmids = "" if pmids.nil? or pmids == "0"
      next if tf =~ /OFFICIAL_/

      species = species.split(";").compact.reject{|s| s.empty?}.collect{|s| 
        case s
        when /Homo sap/i
          "Homo sapiens"
        when /muscul/i
          "Mus musculus"
        else
          s
        end
      }*";"
      source = source.split(";").compact.reject{|s| s.empty?}*";"
      pmids = pmids.split(";").compact.reject{|s| s.empty?}.collect{|s| s.sub(/\s*pmid:\s*/,'').strip}*";"

      values = [target, sign, species, source, pmids]
      values = values.collect{|v| [v]}
      tsv.zip_new(tf, values)
    end

    sheet = book.worksheet 0
    sheet.each do |row|
      target, tf, source, species, pmids = row.values_at(0, 1, 2, 3, 4, 5).collect{|v| v.to_s.gsub(/\s/, ' ') }
      next if tf =~ /OFFICIAL_/

      species = species.split(";").compact.reject{|s| s.empty?}.collect{|s| 
        case s
        when /Homo sap/i
          "Homo sapiens"
        when /muscul/i
          "Mus musculus"
        else
          s
        end
      }*";"
      source = source.split(";").compact.reject{|s| s.empty?}*";"
      pmids = "" if pmids.nil? or pmids == "0"
      pmids = pmids.split(";").compact.reject{|s| s.empty?}.collect{|s| s.sub(/\s*pmid:\s*/,'').strip}*";"

      current = tsv[tf]
      if current and current[0].include? target
        new = []
        Misc.zip_fields(current).each do |ntarget,nsign,nspecies,nsource,npmids|
          if target == ntarget
            if species != nspecies
              nspecies = (nspecies.split(";") + species.split(";")).uniq * ";"
            end
            npmids = (npmids.split(";") + pmids.split(";")).uniq * ";"
          end
          new << [ntarget, nsign, nspecies, nsource, npmids]
        end
        values = Misc.zip_fields(new)
        tsv[tf] = values
      else
        pmids = "" if pmids.nil?

        values = [target, "", species, source, pmids]
        values = values.collect{|v| [v]}
        tsv.zip_new(tf, values)
      end

    end

    tsv.to_s
  end

end

if defined? Entity and defined? Gene and Entity === Gene

  module Gene
    property :is_transcription_factor? => :array2single do
      tfs = TFactS.targets.keys
      self.name.collect{|gene| tfs.include? gene}
    end

    property :transcription_regulators => :array2single do
      Gene.setup(TFactS.regulators.tsv(:persist => true).values_at(*self.name), "Associated Gene Name", self.organism)
    end

    property :transcription_targets => :array2single do
      Gene.setup(TFactS.targets.tsv(:persist => true).values_at(*self.name), "Associated Gene Name", self.organism)
    end
  end
end


if __FILE__ == $0
  Log.severity = 0
  iif TFactS.tf_tg.produce.find
end

