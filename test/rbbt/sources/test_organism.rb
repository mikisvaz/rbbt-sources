require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'rbbt/sources/organism'
require 'test/unit'

class TestEntrez < Test::Unit::TestCase

  def test_known_ids
    assert Organism.known_ids("Hsa").include?("Associated Gene Name")
  end

  def test_location
    assert_equal "share/organisms/Sce/identifiers", Organism.identifiers('Sce')
  end

  def test_identifiers
    assert Organism.identifiers('Hsa').tsv(:key_field => "Entrez Gene ID", :persist => true)['1020']["Associated Gene Name"].include?('CDK5')
    assert Organism.identifiers('Sce').tsv(:persist => true)['S000006120']["Ensembl Gene ID"].include?('YPL199C')
    assert Organism::Sce.identifiers.tsv(:persist => true)['S000006120']["Ensembl Gene ID"].include?('YPL199C')
  end

  def test_lexicon
    assert TSV.open(Organism.lexicon('Sce'))['S000006120'].flatten.include?('YPL199C')
  end

  def test_guess_id
    ensembl = %w(YOL044W YDR289C YAL034C YGR246C ARS519 tH(GUG)E2 YDR218C YLR002C YGL224C)
    gene_name = %w(SNR64 MIP1 MRPS18 TFB2 JEN1 IVY1 TRS33 GAS3)
    assert_equal "Associated Gene Name", Organism::Sce.guess_id(gene_name).first
    assert_equal "Ensembl Gene ID", Organism::Sce.guess_id(ensembl).first
  end

  def test_organisms
    assert Organism.organisms.include? "Hsa"
    assert_equal "Hsa", Organism.organism("Homo sapiens")
  end

  def test_attach_translations
    tsv = TSV.setup({"1020" => []}, :type => :list)
    tsv.key_field = "Entrez Gene ID"
    tsv.fields = []
    tsv.namespace = "Hsa"
    
    Organism::Hsa.attach_translations tsv, "Associated Gene Name"
    Organism::Hsa.attach_translations tsv, "Ensembl Gene ID"

    assert_equal "CDK5", tsv["1020"]["Associated Gene Name"]
  end

  #def test_genes_at_chromosome
  #  pos = [12, 117799500]
  #  assert_equal "ENSG00000089250", Organism::Hsa.genes_at_chromosome_positions(pos.first, pos.last)
  #end

  #def test_genes_at_chromosome_array
  #  pos = [12, [117799500, 106903900]]
  #  assert_equal ["ENSG00000089250", "ENSG00000013503"], Organism::Hsa.genes_at_chromosome_positions(pos.first, pos.last)
  #end
 
  #def test_genes_at_genomic_positions
  #  pos = [[12, 117799500], [12, 106903900], [1, 115259500]]
  #  assert_equal ["ENSG00000089250", "ENSG00000013503", "ENSG00000213281"], Organism::Hsa.genes_at_genomic_positions(pos)
  #end

end


