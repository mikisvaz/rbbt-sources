require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/sources/kegg'
require 'test/unit'

class TestKEGG < Test::Unit::TestCase
  def test_kegg
    assert KEGG.gene_pathway.exists?
  end
end


