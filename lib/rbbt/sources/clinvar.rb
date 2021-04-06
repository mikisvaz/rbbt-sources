require 'rbbt-util'
require 'rbbt/resource'
require 'rbbt/sources/organism'

module ClinVar
  extend Resource
  self.subdir = 'share/databases/ClinVar'

  def self.organism_hg19(org="Hsa")
    Organism.organism_for_build("hg19")
  end

  def self.organism_hg38(org="Hsa")
    Organism.organism_for_build("hg38")
  end


  ClinVar.claim ClinVar.variant_summary, :url, "ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/tab_delimited/variant_summary.txt.gz"

  ClinVar.claim ClinVar.hg19.snv_summary, :proc do
    parser = TSV::Parser.new ClinVar.variant_summary, :type => :list
    dumper = TSV::Dumper.new :fields => parser.fields, :key_field => "Genomic Mutation", :organism => ClinVar.organism_hg19
    dumper.init
    chr_pos, start_pos, ref_pos, alt_pos, assembly_pos = %w(Chromosome PositionVCF ReferenceAlleleVCF AlternateAlleleVCF Assembly).collect{|f| parser.fields.index f}
    TSV.traverse parser, :into => dumper, :bar => true do |allele,values,fields|
      chr, start, ref, alt, assembly = values.values_at chr_pos, start_pos, ref_pos, alt_pos, assembly_pos
      next if assembly != "GRCh37"
      pos, muts = Misc.correct_vcf_mutation(start.to_i, ref, alt)
      res = muts.collect{|m| [[chr, pos, m] * ":", values] }

      res.extend MultipleResult

      res
    end
    dumper.stream
  end

  ClinVar.claim ClinVar.hg38.snv_summary, :proc do
    parser = TSV::Parser.new ClinVar.variant_summary, :type => :list
    dumper = TSV::Dumper.new :fields => parser.fields, :key_field => "Genomic Mutation", :organism => ClinVar.organism_hg38
    dumper.init
    chr_pos, start_pos, ref_pos, alt_pos, assembly_pos = %w(Chromosome PositionVCF ReferenceAlleleVCF AlternateAlleleVCF Assembly).collect{|f| parser.fields.index f}
    TSV.traverse parser, :into => dumper, :bar => true do |allele,values,fields|
      chr, start, ref, alt, assembly = values.values_at chr_pos, start_pos, ref_pos, alt_pos, assembly_pos
      next if assembly != "GRCh38"
      pos, muts = Misc.correct_vcf_mutation(start.to_i, ref, alt)
      res = muts.collect{|m| [[chr, pos, m] * ":", values] }

      res.extend MultipleResult

      res
    end
    dumper.stream
  end


  ClinVar.claim ClinVar.hg19.mi_summary, :proc do
    require 'rbbt/workflow'
    Workflow.require_workflow "Sequence"
    variants = ClinVar.hg19.snv_summary.produce
    muts = CMD.cmd('cut -f 1', :in => variants.open, :pipe => true)
    consequence = Sequence.job(:mutated_isoforms_fast, "Clinvar", :mutations => muts, :non_synonymous => true, :organism => ClinVar.organism_hg19).clean.run(true)

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

  ClinVar.claim ClinVar.hg38.mi_summary, :proc do
    require 'rbbt/workflow'
    Workflow.require_workflow "Sequence"
    variants = ClinVar.hg38.snv_summary.produce
    muts = CMD.cmd('cut -f 1', :in => variants.open, :pipe => true)
    consequence = Sequence.job(:mutated_isoforms_fast, "Clinvar", :mutations => muts, :non_synonymous => true, :organism => ClinVar.organism_hg38).clean.run(true)

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

if __FILE__ == $0
  Log.severity = 0
  ClinVar.hg19.snv_summary.produce
  ClinVar.hg19.mi_summary.produce(true)
  ClinVar.hg38.snv_summary.produce
  ClinVar.hg38.mi_summary.produce(true)
end
