require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'rbbt/sources/organism'
require 'test/unit'
require 'rbbt/sources/ensembl_ftp'

class TestOrganism < Test::Unit::TestCase

  def _test_known_ids
    assert Organism.known_ids("Hsa").include?("Associated Gene Name")
  end

  def _test_location
    assert_equal "share/organisms/Sce/identifiers", Organism.identifiers('Sce')
  end

  def _test_identifiers
    assert Organism.identifiers('Hsa/feb2014').tsv(:key_field => "Entrez Gene ID", :persist => true)['1020']["Associated Gene Name"].include?('CDK5')
    assert Organism.identifiers('Sce').tsv(:persist => true)['S000006120']["Ensembl Gene ID"].include?('YPL199C')
    assert Organism.identifiers("Sce").tsv(:persist => true)['S000006120']["Ensembl Gene ID"].include?('YPL199C')
  end

  def _test_lexicon
    assert TSV.open(Organism.lexicon('Sce'))['S000006120'].flatten.include?('YPL199C')
  end

  def _test_guess_id
    ensembl = %w(YOL044W YDR289C YAL034C YGR246C ARS519 tH(GUG)E2 YDR218C YLR002C YGL224C)
    gene_name = %w(SNR64 MIP1 MRPS18 TFB2 JEN1 IVY1 TRS33 GAS3)
    assert_equal "Associated Gene Name", Organism.guess_id("Sce", gene_name).first
    assert_equal "Ensembl Gene ID", Organism.guess_id("Sce", ensembl).first
  end

  def _test_organisms
    assert Organism.organisms.include? "Hsa"
    assert_equal "Hsa", Organism.organism("Homo sapiens")
  end

  def _test_attach_translations
    tsv = TSV.setup({"1020" => []}, :type => :list)
    tsv.key_field = "Entrez Gene ID"
    tsv.fields = []
    tsv.namespace = "Hsa"
    
    Organism.attach_translations "Hsa", tsv, "Associated Gene Name"
    Organism.attach_translations "Hsa", tsv, "Ensembl Gene ID"

    assert_equal "CDK5", tsv["1020"]["Associated Gene Name"]
  end

  def _test_entrez_taxids
    assert_equal "Hsa", Organism.entrez_taxid_organism('9606')
  end

  def _test_lift_over
    mutation_19 = "19:21131664:T"
    mutation_18 = "19:20923504:T"
    source_build = "Hsa/feb2014"
    target_build = "Hsa/may2009"

    assert_equal mutation_18, Organism.liftOver([mutation_19], source_build, target_build).first
    assert_equal mutation_19, Organism.liftOver([mutation_18], target_build, source_build).first
  end

  def _test_orhtolog
    require 'rbbt/entity/gene'
    assert_equal ["ENSG00000133703"], Gene.setup("Kras", "Associated Gene Name", "Mmu/jun2011").ensembl.ortholog(Organism.default_code("Hsa"))
  end

  def test_chr_sizes
    assert Organism.chromosome_sizes["2"].to_i > 10_000_000
  end

  def _test_build_organism
    assert_equal 'Hsa/may2017', Organism.organism_for_build('hg38')
    assert_equal 'Hsa/feb2014', Organism.organism_for_build('b37')
    assert_equal 'Mmu/may2017', Organism.organism_for_build('mm10')
  end

  #def _test_genes_at_chromosome
  #  pos = [12, 117799500]
  #  assert_equal "ENSG00000089250", Organism::Hsa.genes_at_chromosome_positions(pos.first, pos.last)
  #end

  #def _test_genes_at_chromosome_array
  #  pos = [12, [117799500, 106903900]]
  #  assert_equal ["ENSG00000089250", "ENSG00000013503"], Organism::Hsa.genes_at_chromosome_positions(pos.first, pos.last)
  #end
 
  #def _test_genes_at_genomic_positions
  #  pos = [[12, 117799500], [12, 106903900], [1, 115259500]]
  #  assert_equal ["ENSG00000089250", "ENSG00000013503", "ENSG00000213281"], Organism::Hsa.genes_at_genomic_positions(pos)
  #end

end


