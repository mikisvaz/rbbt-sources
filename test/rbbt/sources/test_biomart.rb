require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

require 'rbbt/sources/pubmed'
require 'test/unit'
require 'rbbt/sources/biomart'
require 'rbbt/sources/organism'
require 'rbbt/util/tmpfile'
require 'test/unit'

class TestBioMart < Test::Unit::TestCase

  def setup
    BioMart.set_archive "feb2014"
  end

  def teardown
    BioMart.unset_archive
  end

  def test_get_Sce
    assert_raise BioMart::QueryError do 
      BioMart.get('scerevisiae_gene_ensembl','entrezgene', ['protein_id'],['with_unknownattr'])
    end

    BioMart.set_archive "feb2023-fungi"
    data = BioMart.get('scerevisiae_eg_gene','entrezgene_id', ['protein_id'],[], nil, :nocache => true, :merge => true, :wget_options => {:quiet => false})
    tsv = TSV.open data, :double, :merge => true
    assert(tsv['852236'][0].include? 'CAA84864.1')

    data = BioMart.get('scerevisiae_eg_gene','entrezgene_id', ['external_gene_id'],[], data, :nocache => false, :wget_options => { :quiet => false} )
    tsv = TSV.open data, :double, :merge => true
    assert(tsv['852236'][1].include? 'YBL044W')
  end

  def test_get_Hsa
    Log.severity = 0
    data = BioMart.get('hsapiens_gene_ensembl','entrezgene', ['protein_id'],[], nil, :nocache => true, :merge => true, :wget_options => {:quiet => false})
    tsv = TSV.open data, :double, :merge => true
    assert(tsv['852236'][0].include? 'CAA84864.1')
  end


  def test_query
    data = BioMart.query('scerevisiae_gene_ensembl','entrezgene', ['protein_id','refseq_peptide','external_gene_id','ensembl_gene_id'], [], nil, :nocache => false, :wget_options => { :quiet => false})
    assert(data['852236']['external_gene_id'].include? 'YBL044W')

    TmpFile.with_file do |f|
      filename = BioMart.query('scerevisiae_gene_ensembl','entrezgene', ['protein_id','refseq_peptide','external_gene_id','ensembl_gene_id'], [], nil, :nocache => false, :wget_options => { :quiet => false}, :filename => f)
      data = TSV.open Open.open(filename)
      assert(data['852236']['external_gene_id'].include? 'YBL044W')
    end
  end

  def _test_tsv
    data = BioMart.tsv('scerevisiae_gene_ensembl',['Entrez Gene', 'entrezgene'], [['Protein ID', 'protein_id'],['RefSeq Peptide','refseq_peptide']], [], nil, :nocache => false, :wget_options => { :quiet => false})
    assert(data['852236']['Protein ID'].include? 'CAA84864')
    assert_equal 'Entrez Gene', data.key_field
    assert_equal ['Protein ID', 'RefSeq Peptide'], data.fields

    TmpFile.with_file do |f|
      filename = BioMart.tsv('scerevisiae_gene_ensembl',['Entrez Gene', 'entrezgene'], [['Protein ID', 'protein_id'],['RefSeq Peptide','refseq_peptide']], [], nil, :nocache => false, :wget_options => { :quiet => false}, :filename => f)
      return
      puts Open.read(filename)
      data = TSV.open Open.open(filename, :merge => true)
      assert(data['852236']['Protein ID'].include? 'CAA84864')
      assert_equal 'Entrez Gene', data.key_field
      assert_equal ['Protein ID', 'RefSeq Peptide'], data.fields
    end
  end

  def __test_chunk
    chrs = %w(I II III IV V VI VII VIII IX X XI XII XIII XIV XV XVI MT 2-micron)
    data = BioMart.query('scerevisiae_gene_ensembl','entrezgene', ['protein_id','refseq_peptide','external_gene_id','ensembl_gene_id'], [], nil, :chunk_filter => ['chromosome_name', chrs], :nocache => false, :wget_options => { :quiet => false})
    assert(data['852236']['external_gene_id'].include? 'YBL044W')

    TmpFile.with_file do |f|
      filename = BioMart.query('scerevisiae_gene_ensembl','entrezgene', ['protein_id','refseq_peptide','external_gene_id','ensembl_gene_id'], [], nil, :nocache => false, :wget_options => { :quiet => false}, :filename => f)
      data = TSV.open Open.open(filename)
      assert(data['852236']['external_gene_id'].include? 'YBL044W')
    end
  end
end
