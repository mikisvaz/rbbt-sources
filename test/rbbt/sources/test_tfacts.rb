require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/sources/tfacts'
require 'test/unit'

class TestTFacts < Test::Unit::TestCase
  def test_tfacts
    assert TFacts.targets.exists?
    assert TFacts.targets_signed.exists?
    assert TFacts.regulators.exists?
  end
end


