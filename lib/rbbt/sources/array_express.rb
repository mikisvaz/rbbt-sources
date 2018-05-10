module ArrayExpress

  def self.tpm(code, organism = Organism.default_code("Hsa"))
    url = "https://www.ebi.ac.uk/gxa/experiments-content/#{code}/resources/ExperimentDownloadSupplier.RnaSeqBaseline/tpms.tsv"
    io = TSV.traverse Open.open(url), :type => :line, :into => :stream do |line|
      next if line =~ /^#/
      parts = line.split("\t")
      line = parts[0] << "\t" << parts[2..-1] * "\t"
      line = "#" + line if line =~ /Gene ID/
      line
    end
    tsv = TSV.open(io, :type => :list, :cast => :to_f)
    tsv.key_field = "Ensembl Gene ID"
    tsv.namespace = organism
    tsv
  end
end
