require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/sources/string'
require 'test/unit'

class TestSTRING < Test::Unit::TestCase
  def test_string
    assert STRING.protein_protein.exists?
  end
end


