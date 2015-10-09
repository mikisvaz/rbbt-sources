require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/workflow'
Workflow.require_workflow "Genomics"

require 'rbbt/entity/gene'
require 'rbbt/sources/go'
require 'test/unit'


class TestGo < Test::Unit::TestCase
  def test_go
    assert_match('vacuole inheritance',GO::id2name('GO:0000011'))
    assert_equal(['vacuole inheritance','alpha-glucoside transport'], GO::id2name(['GO:0000011','GO:0000017']))
  end

  def test_ancestors
    assert GO.id2ancestors('GO:0000001').include? 'GO:0048308'
  end

  def test_namespace
    assert_equal 'biological_process', GO.id2namespace('GO:0000001')
  end

  def test_ancestors
    term = GOTerm.setup("GO:0005634")
  end

  def test_ancestry
    term = GOTerm.setup("GO:0005634")
    term.ancestry.include? "GO:0005634"
  end

  def test_ancestors_in
    term = GOTerm.setup("GO:0005730")
    valid = %w(GO:0005886 GO:0005634 GO:0005730 GO:0005829)
    iii term.name
    iii GO.ancestors_in(term, valid)
  end

  def test_groups
    list = Gene.setup(%w(FBXW7 SP140 LHX2 KIF23),
                      "Associated Gene Name", Organism.default_code("Hsa"))

    valid = %w(GO:0005886 GO:0005634 GO:0005730 GO:0005829 )
    valid = %w(GO:0005634 GO:0005730)
    iii GO.group_genes(list, valid)
  end

  def test_nucleolus
    nuo = "GO:0005730"
    nu = "GO:0005634"
  end
end


