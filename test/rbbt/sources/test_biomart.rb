require File.dirname(__FILE__) + '/../../test_helper'
require 'rbbt/sources/biomart'
require 'test/unit'

class TestBioMart < Test::Unit::TestCase

  def test_get
    assert_raise BioMart::QueryError do 
      BioMart.get('scerevisiae_gene_ensembl','entrezgene', ['protein_id'],['with_unknownattr'])
    end

    data = BioMart.get('scerevisiae_gene_ensembl','entrezgene', ['protein_id'],[], nil, :nocache => false, :wget_options => { :quiet => false})
    assert(data['852236']['protein_id'].include? 'CAA84864')

    data = BioMart.get('scerevisiae_gene_ensembl','entrezgene', ['external_gene_id'],[], data, :nocache => false, :wget_options => { :quiet => false} )
    assert(data['852236']['external_gene_id'].include? 'YBL044W')
  end

  def test_query
    data = BioMart.query('scerevisiae_gene_ensembl','entrezgene', ['protein_id','refseq_peptide','external_gene_id','ensembl_gene_id'], [], nil, :nocache => false, :wget_options => { :quiet => false})

    assert(data['852236']['external_gene_id'].include? 'YBL044W')
  end

  def test_tsv
    data = BioMart.tsv('scerevisiae_gene_ensembl',['Entrez Gene', 'entrezgene'], [['Protein ID', 'protein_id'],['RefSeq Peptide','refseq_peptide']], [], nil, :nocache => false, :wget_options => { :quiet => false})

    assert(data['852236']['Protein ID'].include? 'CAA84864')
    assert_equal 'Entrez Gene', data.key_field
    assert_equal ['Protein ID', 'RefSeq Peptide'], data.fields
  end
end


