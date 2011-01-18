require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'rbbt/sources/organism'
require 'test/unit'

class TestEntrez < Test::Unit::TestCase
  def test_identifiers
    assert TSV.new(Organism.identifiers('Sce'))['S000006120']["Ensembl Gene ID"].include?('YPL199C')
    assert TSV.new(Organism::Sce.identifiers)['S000006120']["Ensembl Gene ID"].include?('YPL199C')
    assert TSV.new(Organism.identifiers('Hsa'))['1020']["Associated Gene Name"].include?('CDK5')
  end

  def test_lexicon
    assert TSV.new(Organism.lexicon('Sce'))['S000006120'].flatten.include?('YPL199C')
  end

  def test_guess_id
    ensembl = %w(YOL044W YDR289C YAL034C YGR246C ARS519 tH(GUG)E2 YDR218C YLR002C YGL224C)
    gene_name = %w(SNR64 MIP1 MRPS18 TFB2 JEN1 IVY1 TRS33 GAS3)
    assert_equal "Ensembl Gene ID", Organism::Sce.guess_id(ensembl).first
    assert_equal "Associated Gene Name", Organism::Sce.guess_id(gene_name).first
  end

  def test_organisms
    assert Organism.organisms.include? "Hsa"
    assert_equal "Hsa", Organism.organism("Homo sapiens")
  end
end


