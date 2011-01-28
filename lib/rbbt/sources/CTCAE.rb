require 'rbbt-util'
require 'rbbt/util/excel2tsv'

module CTCAE
  Rbb.claim "CTCAE", TSV.excel2tsv('http://evs.nci.nih.gov/ftp1/CTCAE/CTCAE_4.03_2010-06-14.xls'), 'CTCAE'
end
