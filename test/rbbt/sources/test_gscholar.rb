require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/sources/gscholar'
require 'test/unit'

class TestGScholar < Test::Unit::TestCase
  def test_citation
    assert_match /cites/, GoogleScholar.citation_link("Ten Years of Pathway Analysis: Current Approaches and Outstanding Challenges").to_s
    assert_match /\d+/, GoogleScholar.number_cites("Ten Years of Pathway Analysis: Current Approaches and Outstanding Challenges").to_s
  end

end


