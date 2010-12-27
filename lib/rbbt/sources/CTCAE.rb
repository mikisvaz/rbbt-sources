require 'rbbt-util'
require 'rbbt/util/excel2tsv'

module CTCAE
  Rbbt.add_datafiles "CTCAE" => ['CTCAE', Proc.new{TSV.excel2tsv('http://evs.nci.nih.gov/ftp1/CTCAE/CTCAE_4.03_2010-06-14.xls').to_s}]
end
