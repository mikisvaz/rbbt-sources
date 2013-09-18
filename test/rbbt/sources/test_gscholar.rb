require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/sources/gscholar'
require 'test/unit'

class TestGScholar < Test::Unit::TestCase
  def test_citation
    assert_match GoogleScholar.citation_link("Ten Years of Pathway Analysis: Current Approaches and Outstanding Challenges").to_s, /cites/
    assert_match GoogleScholar.number_cites("Ten Years of Pathway Analysis: Current Approaches and Outstanding Challenges").to_s, /\d+/
  end

end


