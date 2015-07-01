require 'rbbt-util'
require 'rbbt/resource'

module ClinVar
  extend Resource
  self.subdir = 'share/databases/ClinVar'

  def self.organism(org="Hsa")
    Organism.default_code(org)
  end

  ClinVar.claim ClinVar.variant_summary, :url, "ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/tab_delimited/variant_summary.txt.gz"

  ClinVar.claim ClinVar.snv_summary, :proc do
    url = "ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/tab_delimited/variant_summary.txt.gz"
    io = TSV.traverse ClinVar.variant_summary, :type => :array, :into => :stream do |line|
      line = Misc.fixutf8 line
      begin
        res = []
        if line =~ /^#/
          parts = line.split("\t")
          res << (["#Genomic Mutation"] + parts[1..12] + parts[15..23]) * "\t"
        else
          next unless line =~ /GRCh37/ 
          next if line =~ /(copy number|NT expansion|duplication|indel)/
          parts = line.split("\t")
          chr,pos,ref,mut = parts.values_at 13, 14, 25, 26
          next if ref == 'na' or mut == 'na'

          pos, muts = Misc.correct_mutation(pos.to_i,ref,mut)
          muts.each do |mut|
            mutation = [chr,pos,mut] * ":"
            res << ([mutation] + parts[1..12] + parts[15..23]) * "\t"
          end
        end
        res.extend MultipleResult
        res
      rescue
        Log.exception $!
        raise $!
      end
    end
    Misc.sort_stream(io)
  end

  ClinVar.claim ClinVar.mi_summary, :proc do
    require 'rbbt/workflow'
    Workflow.require_workflow "Sequence"
    variants = ClinVar.snv_summary.produce
    muts = CMD.cmd('cut -f 1', :in => variants.open, :pipe => true)
    consequence = Sequence.job(:mutated_isoforms_fast, "Clinvar", :mutations => muts, :non_synonymous => true).clean.run(true)

    options = TSV.parse_header(variants).options.merge({:key_field => "Mutated Isoform"})
    fields = options[:fields].length
    dumper = TSV::Dumper.new options
    dumper.init
    pasted = TSV.paste_streams([variants, TSV.get_stream(consequence)])
    TSV.traverse pasted, :into => dumper, :bar => true do |mutation,values|
      begin
        mis = values[fields..-1].flatten
        next if mis.empty?
        res = []
        res.extend MultipleResult
        mis.each do |mi|
          res << [mi, values[0..fields-1]]
        end
        res
      rescue
        Log.exception $!
        raise $!
      end
    end
    dumper.stream
  end
end

iif ClinVar.mi_summary.produce(true).find if __FILE__ == $0

