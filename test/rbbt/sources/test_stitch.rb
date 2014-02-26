require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/sources/stitch'
require 'test/unit'

class TestSTITCH < Test::Unit::TestCase
  def test_stitch
    assert STITCH.protein_chemical.exists?
  end
end


