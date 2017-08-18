require 'rbbt-util'

module Barcode
  extend Resource
  self.subdir = "share/databases/Barcode"

  Barcode.claim Barcode.transcriptome, :proc do
    tsv = TSV.open(Open.open("http://rafalab.jhsph.edu/barcode/abc.ntc.GPL570.csv"), 
                   :fix => Proc.new{|l| l.delete('"').tr(',', "\t")}, :header_hash => "",
                  :type => :list, :cast => :to_f)
    io = Open.open("http://rafalab.jhsph.edu/barcode/abc.ntc.GPL570.csv")
    fields = io.gets.chomp.delete('"').split(',')
    io.close
    fields.shift
    tsv.fields = fields
    tsv.key_field = "AFFY HG U133-PLUS-2"
    tsv.to_s
  end

end
