require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/sources/pharmagkb'
require 'test/unit'

class TestPGKB < Test::Unit::TestCase
  def test_pharmagkb
    assert PharmaGKB.gene_pathway.exists?
  end
end


