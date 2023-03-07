require 'rbbt-util'
require 'rbbt/tsv'
require 'rbbt/resource'
require 'rbbt/util/filecache'
require 'set'

module Entrez

  Rbbt.claim Rbbt.share.databases.entrez.gene_info, :url, 'ftp://ftp.ncbi.nih.gov/gene/DATA/gene_info.gz'
  Rbbt.claim Rbbt.share.databases.entrez.gene2pubmed, :url, 'ftp://ftp.ncbi.nih.gov/gene/DATA/gene2pubmed.gz'

  def self.entrez2native(taxs, options = {})
    options = Misc.add_defaults options, :key_field => 1, :fields => [5], :persist => true, :merge => true

    taxs = [taxs] unless Array === taxs
    options.merge! :grep => taxs.collect{|t| "^" + t.to_s}, :fixed_grep => false

    tsv = Rbbt.share.databases.entrez.gene_info.tsv :flat, options
    tsv.key_field = "Entrez Gene ID"
    tsv.fields    = ["Native ID"]
    tsv
  end

  def self.entrez2name(taxs, options = {})
    options = Misc.add_defaults options, :key_field => 1, :fields => [2], :persist => true, :merge => true

    taxs = [taxs] unless Array === taxs
    options.merge! :grep => taxs.collect{|t| "^" + t.to_s}, :fixed_grep => false

    tsv = Rbbt.share.databases.entrez.gene_info.tsv :flat, options
    tsv.key_field = "Entrez Gene ID"
    tsv.fields    = ["Associated Gene Name"]
    tsv
  end


  def self.entrez2pubmed(taxs)
    options = {:key_field => 1, :fields => [2], :persist => true, :merge => true}

    taxs = [taxs] unless taxs.is_a?(Array)
    options.merge! :grep => taxs.collect{|t| "^" + t.to_s}, :fixed_grep => false

    Rbbt.share.databases.entrez.gene2pubmed.tsv :flat, options
  end

  class Gene
    attr_reader :organism, :symbol, :description, :aka, :protnames, :summary, :comentaries

    def initialize(xml)
      return if xml.nil?

      @organism    = xml.scan(/<Org-ref_taxname>(.*)<\/Org-ref_taxname>/s)
      @symbol      = xml.scan(/<Gene-ref_locus>(.*)<\/Gene-ref_locus>/s)
      @description = xml.scan(/<Gene-ref_desc>(.*)<\/Gene-ref_desc>/s)
      @aka         = xml.scan(/<Gene-ref_syn_E>(.*)<\Gene-ref_syn_E>/s)
      @protnames   = xml.scan(/<Prot-ref_name_E>(.*)<\/Prot-ref_name_E>/s)
      @summary     = xml.scan(/<Entrezgene_summary>(.*)<\/Entrezgene_summary>/s)
      @comentaries = xml.scan(/<Gene-commentary_text>(.*)<\/Gene-commentary_text>/s)


    end

    # Joins the text from symbol, description, aka, protnames, and
    # summary
    def text
      #[@organism, @symbol, @description, @aka,  @protnames, @summary,@comentaries.join(". ")].join(". ") 
      [@symbol, @description, @aka,  @protnames, @summary].flatten.join(". ") 
    end
  end

  private 


  def self.get_gene(geneids)
    _array = Array === geneids

    geneids = [geneids] unless Array === geneids
    geneids = geneids.compact.collect{|id| id}

    result_files = FileCache.cache_online_elements(geneids, 'gene-{ID}.xml') do |ids|
      result = {}
      values = []
      Misc.divide(ids, (ids.length / 100) + 1).each do |list|
        begin
          Misc.try3times do
            url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gene&retmode=xml&id=#{list * ","}" 

            xml = Open.read(url, :wget_options => {:quiet => true}, :nocache => true)

            values += xml.scan(/(<Entrezgene>.*?<\/Entrezgene>)/sm).flatten
          end
        rescue
          Log.error $!.message
        end
      end

      values.each do |xml|
        geneid = xml.match(/<Gene-track_geneid>(\d+)/)[1]

        result[geneid] = xml
      end

      result
    end

    genes = {}
    geneids.each{|id| next if id.nil? or result_files[id].nil?; genes[id] = Gene.new(Open.read(result_files[id])) }

    if _array
      genes
    else
      genes.values.first
    end
  end

  # Counts the words in common between a chunk of text and the text
  # found in Entrez Gene for that particular gene. The +gene+ may be a
  # gene identifier or a Gene class instance.
  def self.gene_text_similarity(gene, text)
    require 'rbbt/bow/bow'

    case
    when Entrez::Gene === gene
      gene_text = gene.text
    when String === gene || Fixnum === gene
      begin
        gene_text =  get_gene(gene).text
      rescue NoMethodError, CMD::CMDError
        return 0
      end
    else
      return 0
    end

    gene_words = gene_text.words.to_set
    text_words = text.words.to_set

    return 0 if gene_words.empty? || text_words.empty?

    common = gene_words.intersection(text_words)
    common.length / (gene_words.length + text_words.length).to_f
  end
end
