require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/sources/HPRD'
require 'test/unit'

class TestPina < Test::Unit::TestCase
  def __test_HPRD
    ddd HPRD.protein_protein.find.produce
  end
end


