require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/sources/matador'
require 'test/unit'

class TestMatador < Test::Unit::TestCase
  def test_matador
    assert Matador.protein_drug.exists?
  end
end


