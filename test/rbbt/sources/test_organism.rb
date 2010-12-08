require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'rbbt/sources/organism'
require 'test/unit'

class TestEntrez < Test::Unit::TestCase
  def test_identifiers
    assert Organism.identifiers('Sce')['S000006120']["Ensembl Gene ID"].include?('YPL199C')
    assert Organism::Sce.identifiers['S000006120']["Ensembl Gene ID"].include?('YPL199C')
    #assert Organism.identifiers('Hsa')['1020']["Associated Gene Name"].include?('CDK5')
  end

  def test_lexicon
    assert Organism.lexicon('Sce')['S000006120'].flatten.include?('YPL199C')
  end
end


