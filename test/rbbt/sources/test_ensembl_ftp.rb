require File.expand_path(__FILE__).sub(%r(/test/.*), '/test/test_helper.rb')
require File.expand_path(__FILE__).sub(%r(.*/test/), '').sub(/test_(.*)\.rb/,'\1')

class TestEnsemblFTP < Test::Unit::TestCase
  def test_ftp_for
    assert_nothing_raised do
      Ensembl::FTP.ftp_name_for("Hsa/feb2023", 'fasta')
    end
  end
end

