require 'rbbt'
require 'rbbt/resource'
module COSMIC
  extend Resource
  self.subdir = "share/databases/COSMIC"

  COSMIC.claim COSMIC.Mutations, :proc do 
    url = "ftp://ftp.sanger.ac.uk/pub/CGP/wgs/data_export/CosmicWGS_MutantExport_v61_260912.tsv.gz"

    tsv = TSV.open(Open.open(url), :type => :list, :header_hash => "", :key_field => "Mutation ID", :namespace => "Hsa/jun2011")
    tsv.fields = tsv.fields.collect{|f| f == "Gene name" ? "Associated Gene Name" : f}
    tsv.add_field "Genomic Mutation" do |mid, values|
      position = values["Mutation GRCh37 genome position"]
      cds = values["Mutation CDS"]
      if position.nil? or position.empty?
        nil
      else
        position = position.split("-").first
        if cds.nil?
          position
        else
          change = case
                   when cds =~ />/
                     cds.split(">").last
                   when cds =~ /del/
                     deletion = cds.split("del").last
                     case
                     when deletion =~ /^\d+$/
                       "-" * deletion.to_i 
                     when deletion =~ /^[ACTG]+$/i
                       "-" * deletion.length
                     else
                       Log.debug "Unknown deletion: #{ deletion }"
                       deletion
                     end
                   when cds =~ /ins/
                     insertion = cds.split("ins").last
                     case
                     when insertion =~ /^\d+$/
                       "+" + "N" * insertion.to_i 
                     when insertion =~ /^[NACTG]+$/i
                       "+" + insertion
                     else
                       Log.debug "Unknown insertion: #{insertion }"
                       insertion
                     end
                   else
                     Log.debug "Unknown change: #{cds}"
                     "?(" << cds << ")"
                   end
          position + ":" + change
        end
      end
    end
    tsv.to_s.gsub(/^(\d)/m,'COSM\1').gsub(/(\d)-(\d)/,'\1:\2')
  end
end
