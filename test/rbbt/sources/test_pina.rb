require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/sources/pina'
require 'test/unit'

class TestPina < Test::Unit::TestCase
  def test_pina
    assert Pina.protein_protein.exists?
  end
end


