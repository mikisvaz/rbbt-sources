require 'rbbt-util'
require 'rbbt/resource'

# CITE: Genomic Determinants of Protein Abundance Variation in Colorectal
# Cancer Cells PMID: 28854368
#
# Roumeliotis TI, Williams SP, Gonçalves E, et al. Genomic Determinants of
# Protein Abundance Variation in Colorectal Cancer Cells. Cell Reports.
# 2017;20(9):2201-2214. doi:10.1016/j.celrep.2017.08.010.

module COREADPhosphoProteome
  extend Resource
  self.subdir = 'share/databases/COREADPhosphoProteome'

  #def self.organism(org="Hsa")
  #  Organism.default_code(org)
  #end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib

  

  COREADPhosphoProteome.claim COREADPhosphoProteome[".source/mmc3.xlsx"], :url, "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5583477/bin/mmc3.xlsx"

  COREADPhosphoProteome.claim COREADPhosphoProteome.data, :proc do 
    require 'rbbt/tsv/excel'
    io = TSV.excel COREADPhosphoProteome[".source/mmc3.xlsx"].produce.find, :text => true
    TSV.collapse_stream io
  end

  COREADPhosphoProteome.claim COREADPhosphoProteome.phosphosite_levels, :proc do 
    tsv = COREADPhosphoProteome.data.tsv 
    name, seq, site, kinases, name, *cell_lines = tsv.fields 
    tsv.add_field "Phosphosite" do |uni,values_list|
      Misc.zip_fields(values_list).collect{|values|
        name, seq, site, kinases, kegg_name, *vals = values 
        [name, site] * ":"
      }
    end
    tsv.reorder "Phosphosite", cell_lines, :zipped => true
  end

  COREADPhosphoProteome.claim COREADPhosphoProteome.phosphosite_binary, :proc do
    require 'rbbt/matrix'
    require 'rbbt/matrix/barcode'

    m = RbbtMatrix.new COREADPhosphoProteome.phosphosite_levels.find
    a = m.to_activity(3).tsv(false)
    a
  end

  COREADPhosphoProteome.claim COREADPhosphoProteome.signor_activity_present, :proc do
    require 'rbbt/sources/signor'
    signor = Signor.phospho_sites.tsv

    signor.add_field "Fixed" do |k,l|
      case l.uniq.length 
      when 1
        l.first
      when 2
        "Unclear"
      end
    end
    signor = signor.slice("Fixed").to_single

    parser = TSV::Parser.new COREADPhosphoProteome.phosphosite_levels
    dumper = TSV::Dumper.new parser.options
    dumper.init
    cell_lines = parser.fields
    TSV.traverse parser, :into => dumper do |site,values|
      osite = site
      site = site.sub(':S', ':Ser').sub(':T', ':Thr').sub(':Y', ':Tyr')
      next unless signor.include? site
      new_values = values.flatten.zip(cell_lines).collect{|value,cell_line|
        next if signor[site] == "Unclear"
        case value
        when nil, ""
          signor[site] == "Activates" ? -1 : 1
        else
          signor[site] == "Activates" ? 1 : -1
        end
      }
      [site, new_values]
    end
  end

  COREADPhosphoProteome.claim COREADPhosphoProteome.signor_activity_100, :proc do
    require 'rbbt/sources/signor'
    signor = Signor.phospho_sites.tsv

    signor.add_field "Fixed" do |k,l|
      case l.uniq.length 
      when 1
        l.first
      when 2
        "Unclear"
      end
    end
    signor = signor.slice("Fixed").to_single

    parser = TSV::Parser.new COREADPhosphoProteome.phosphosite_levels
    dumper = TSV::Dumper.new parser.options
    dumper.init
    TSV.traverse parser, :into => dumper do |site,values|
      osite = site
      site = site.sub(':S', ':Ser').sub(':T', ':Thr').sub(':Y', ':Tyr')
      next unless signor.include? site
      new_values = values.flatten.collect{|value|
        next if signor[site] == "Unclear"
        case value
        when nil, ""
          signor[site] == "Activates" ? -1 : 1
        else
          if value.to_f >= 100
            signor[site] == "Activates" ? 1 : -1
          else
            signor[site] == "Activates" ? -1 : 1
          end
        end
      }
      [site, new_values]
    end
  end

  COREADPhosphoProteome.claim COREADPhosphoProteome.signor_activity_levels, :proc do
    require 'rbbt/sources/signor'
    signor = Signor.phospho_sites.tsv

    signor.add_field "Fixed" do |k,l|
      case l.uniq.length 
      when 1
        l.first
      when 2
        "Unclear"
      end
    end
    signor = signor.slice("Fixed").to_single


    parser = TSV::Parser.new COREADPhosphoProteome.phosphosite_binary
    dumper = TSV::Dumper.new parser.options
    dumper.init
    TSV.traverse parser, :into => dumper do |site,values|
      osite = site
      site = site.first if Array === site
      site = site.sub(':S', ':Ser').sub(':T', ':Thr').sub(':Y', ':Tyr')
      next unless signor.include? site
      max = values.flatten.max
      new_values = values.flatten.collect{|value|
        next if signor[site] == "Unclear"
        case value
        when nil, ""
          signor[site] == "Activates" ? -1 : 1
        else
          if value == max
            signor[site] == "Activates" ? 1 : -1
          else
            signor[site] == "Activates" ? -1 : 1
          end
        end
      }
      [site, new_values]
    end
  end

  COREADPhosphoProteome.claim COREADPhosphoProteome.cascade_levels, :proc do
    require 'rbbt/sources/CASCADE'

    cascade_proteins = CASCADE.members.tsv.values.flatten.compact.uniq
    tsv = COREADPhosphoProteome.phosphosite_levels.tsv
    tsv.select do |site,values|
      cascade_proteins.include? site.split(":").first
    end
  end
end

iif COREADPhosphoProteome.data.produce.find if __FILE__ == $0
iif COREADPhosphoProteome.phosphosite_levels.produce.find if __FILE__ == $0
iif COREADPhosphoProteome.phosphosite_binary.produce.find if __FILE__ == $0
iif COREADPhosphoProteome.signor_activity_present.produce(true).find if __FILE__ == $0
iif COREADPhosphoProteome.cascade_levels.produce.find if __FILE__ == $0

