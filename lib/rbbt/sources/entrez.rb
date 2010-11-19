require 'rbbt/util/base'
require 'rbbt/util/open'
require 'rbbt/util/tmpfile'
require 'rbbt/util/filecache'
require 'rbbt/util/tsv'
require 'rbbt/bow/bow'
require 'set'


module Entrez

  class NoFileError < StandardError; end

  def self.entrez2native(taxs, native = nil, fix = nil, check = nil)

    raise NoFileError, "Install the Entrez gene_info file" unless File.exists? File.join(Rbbt.datadir, 'dbs/entrez/gene_info')

    native ||= 5

    taxs = [taxs] unless taxs.is_a?(Array)
    taxs = taxs.collect{|t| t.to_s}

    lexicon = {}
    Open.read(File.join(Rbbt.datadir, 'dbs/entrez/gene_info'), :grep => "^#{taxs *"\|"}[[:space:]]") do |l| 
      parts = l.chomp.split(/\t/)
      next if parts[native] == '-'
      entrez = parts[1]
      parts[native].split(/\|/).each{|id|
        id = fix.call(id) if fix
        next if check && !check.call(id)

        lexicon[entrez] ||= []
        lexicon[entrez] << id
      }
    end

    lexicon
  end

  def self.entrez2pubmed(taxs)
    raise NoFileError, "Install the Entrez gene2pubmed file" unless File.exists? File.join(Rbbt.datadir, 'dbs/entrez/gene2pubmed')

    taxs = [taxs] unless taxs.is_a?(Array)
    taxs = taxs.collect{|t| t.to_s}

    data = {}
 
    data = TSV.new(File.join(Rbbt.datadir, 'dbs/entrez/gene2pubmed'), :native => 1, :extra => 2,  :grep => "^#{taxs *"\|"}[[:space:]]").each{|code, value_lists| value_lists.flatten!}

    data
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

  @@last = Time.now
  @@entrez_lag = 1
  def self.get_online(geneids)

    geneids_list = ( geneids.is_a?(Array) ? geneids.join(',') : geneids.to_s )
    url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gene&retmode=xml&id=#{geneids_list}" 

    diff = Time.now - @@last
    sleep @@entrez_lag - diff unless diff > @@entrez_lag

    xml = Open.read(url, :quiet => true, :nocache => true)

    @@last = Time.now

    genes = xml.scan(/(<Entrezgene>.*?<\/Entrezgene>)/sm).flatten

    if geneids.is_a? Array
      list = {}
      genes.each_with_index{|gene,i|
        geneid = geneids[i]
        list[geneid ] = gene
      }
      return list
    else
      return genes.first
    end

  end

  public

  def self.gene_filename(id)
    'gene-' + id.to_s + '.xml'
  end

  def self.get_gene(geneid)

    return nil if geneid.nil?

    if Array === geneid
      missing = []
      list = {}

      geneid.each{|p|
        next if p.nil?
        filename = gene_filename p    
        if File.exists? FileCache.path(filename)
          list[p] = Gene.new(Open.read(FileCache.path(filename)))
        else
          missing << p
        end
      }

      return list unless missing.any?
      genes = get_online(missing)

      genes.each{|p, xml|
        filename = gene_filename p    
        FileCache.add(filename,xml) unless File.exist? FileCache.path(filename)
        list[p] =  Gene.new(xml)
      }

      return list

    else
      filename = gene_filename geneid    

      if File.exists? FileCache.path(filename)
        return Gene.new(Open.read(FileCache.path(filename)))
      else
        xml = get_online(geneid)
        FileCache.add(filename,xml)

        return Gene.new(xml)
      end
    end
  end

  # Counts the words in common between a chunk of text and the text
  # found in Entrez Gene for that particular gene. The +gene+ may be a
  # gene identifier or a Gene class instance.
  def self.gene_text_similarity(gene, text)

    case
    when Entrez::Gene === gene
      gene_text = gene.text
    when String === gene || Fixnum === gene
      gene_text =  get_gene(gene).text
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
