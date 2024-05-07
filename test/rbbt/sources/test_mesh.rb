require File.expand_path(__FILE__).sub(%r(/test/.*), '/test/test_helper.rb')
require File.expand_path(__FILE__).sub(%r(.*/test/), '').sub(/test_(.*)\.rb/,'\1')

class TestMESH < Test::Unit::TestCase
  def test_vocab
    tsv = MeSH.vocabulary.tsv
    assert_equal "3T3 Cells", tsv["D016475"]
  end
end

