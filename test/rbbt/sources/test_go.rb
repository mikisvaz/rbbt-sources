require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/workflow'
Workflow.require_workflow "Genomics"

require 'rbbt/entity/gene'
require 'rbbt/sources/go'
require 'test/unit'


class TestGo < Test::Unit::TestCase
  def _test_go
    assert_match('vacuole inheritance',GO::id2name('GO:0000011'))
    assert_equal(['vacuole inheritance','alpha-glucoside transport'], GO::id2name(['GO:0000011','GO:0000017']))
  end

  def _test_ancestors
    assert GO.id2ancestors('GO:0000001').include? 'GO:0048308'
  end

  def _test_namespace
    assert_equal 'biological_process', GO.id2namespace('GO:0000001')
  end

  def _test_ancestors
    term = GOTerm.setup("GO:0005634")
  end

  def _test_ancestry
    term = GOTerm.setup("GO:0005634")
    term.ancestry.include? "GO:0005634"
  end

  def _test_ancestry_in
    term = GOTerm.setup("GO:0005634")
    valid = %w(GO:0005886 GO:0005634 GO:0005730 GO:0005829)
    iii GO.ancestors_in(term, valid)
  end

  def test_groups
    list = Gene.setup(%w(ENSG00000009413
                        ENSG00000038295
                        ENSG00000038427
                        ENSG00000047457
                        ENSG00000058668
                        ENSG00000065361
                        ENSG00000070778
                        ENSG00000072364
                        ENSG00000073711
                        ENSG00000075420
                        ENSG00000088387
                        ENSG00000096384
                        ENSG00000100345
                        ENSG00000102804
                        ENSG00000102910
                        ENSG00000103657
                        ENSG00000104043
                        ENSG00000106772
                        ENSG00000107186
                        ENSG00000108262
                        ENSG00000261163
                        ENSG00000263077
                        ENSG00000101654
                        ENSG00000111012), :organism => Organism.default_code("Hsa"))

    valid = %w(GO:0005886 GO:0005634 GO:0005730 GO:0005829 )
    iii GO.group_genes(list, valid)
  end

  def _test_nucleolus
    nuo = "GO:0005730"
    nu = "GO:0005634"
  end
end


