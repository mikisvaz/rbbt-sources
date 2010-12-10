require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'rbbt/sources/organism'
require 'test/unit'

class TestEntrez < Test::Unit::TestCase
  def test_identifiers
    assert TSV.new(Organism.identifiers('Sce'))['S000006120']["Ensembl Gene ID"].include?('YPL199C')
    assert TSV.new(Organism::Sce.identifiers)['S000006120']["Ensembl Gene ID"].include?('YPL199C')
    #assert Organism.identifiers('Hsa')['1020']["Associated Gene Name"].include?('CDK5')
  end

  def test_lexicon
    assert TSV.new(Organism.lexicon('Sce'))['S000006120'].flatten.include?('YPL199C')
  end
end


