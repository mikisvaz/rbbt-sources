require 'rbbt'
require 'libxml'
require 'rbbt/sources/gscholar'

# This module offers an interface with PubMed, to perform queries, and
# retrieve simple information from articles. It uses the caching
# services of Rbbt.
module PubMed

  private
  @@pubmed_lag = 1
  def self.get_online(pmids)

    pmids_complete =  pmids.is_a?(Array) ? pmids : [pmids]

    url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi" 
    articles = []

    Misc.divide(pmids.sort_by{|v| v.nil? ? 0 : v.to_i}, (pmids.length / 1000) + 1).each do |pmid_list|
      postdata = "db=pubmed&retmode=xml&id=#{pmid_list* ","}"
      xml = TmpFile.with_file(postdata) do |postfile|
        Open.read(url, :quiet => true, :nocache => true, :nice => @@pubmed_lag, :nice_key => "PubMed", "--post-file=" => postfile)
      end

      articles += xml.scan(/(<PubmedArticle>.*?<\/PubmedArticle>)/smu).flatten
    end

    if pmids.is_a? Array
      list = {}
      articles.each{|article|
        pmid = article.scan(/<PMID[^>]*?>(.*?)<\/PMID>/).flatten.first
        list[pmid] = article
      }
      return list
    else
      return articles.first
    end

  end

  public

  # Processes the xml with an articles as served by MedLine and extracts
  # the abstract, title and journal information
  class Article


    XML_KEYS = [
      [:title    , "ArticleTitle"],
      [:journal  , "Journal/Title"],
      [:issue    , "Journal/JournalIssue/Issue"],
      [:volume   , "Journal/JournalIssue/Volume"],
      [:issn     , "Journal/ISSN"],
      [:year     , "Journal/JournalIssue/PubDate/Year"],
      [:month    , "Journal/JournalIssue/PubDate/Month"],
      [:pages    , "Pagination/MedlinePgn"],
      [:author    , "AuthorList/Author"],
      [:abstract , "Abstract/AbstractText"],
    ]

    PMC_PDF_URL = "http://www.ncbi.nlm.nih.gov/pmc/articles/PMCID/pdf/"

    def self.escape_title(title)
      title.gsub(/(\w*[A-Z][A-Z]+\w*)/, '{\1}')
    end

    def self.make_bibentry(lastname, year, title)
      words = title.downcase.scan(/\w+/)
      if words.first.length > 3
        abrev = words.first
      else
        abrev = words[0..2].collect{|w| w.chars.first} * ""
      end
      [lastname.gsub(/\s/,'_'), year || "NOYEAR", abrev] * ""
    end
    def self.parse_xml(xml)
      parser  = LibXML::XML::Parser.string(xml)
      pubmed  = parser.parse.find("/PubmedArticle").first
      medline = pubmed.find("MedlineCitation").first
      article = medline.find("Article").first

      info = {}

      info[:pmid] = medline.find("PMID").first.content

      XML_KEYS.each do |p|
        name, key = p
        node = article.find(key).first

        next if node.nil?

        info[name] = node.content
      end

      bibentry = nil
      info[:author] = article.find("AuthorList/Author").collect do |author|
        begin
          lastname = author.find("LastName").first.content
          if author.find("ForeName").first.nil?
            forename = nil
          else
            forename = author.find("ForeName").first.content.split(/\s/).collect{|word| if word.length == 1; then word + '.'; else word; end} * " "
          end
          bibentry ||= make_bibentry lastname, info[:year], info[:title]
        rescue
        end
        [lastname, forename] * ", "
      end * " and "

      info[:bibentry] = bibentry.downcase if bibentry

      info[:pmc_pdf] = pubmed.find("PubmedData/ArticleIdList/ArticleId").select{|id| id[:IdType] == "pmc"}.first

      if info[:pmc_pdf]
        info[:pmc_pdf] = PMC_PDF_URL.sub(/PMCID/, info[:pmc_pdf].content)
      end

      info
    end

    attr_accessor :title, :abstract, :journal, :author, :pmid, :bibentry, :pmc_pdf, :gscholar_pdf, :pdf_url
    attr_accessor *XML_KEYS.collect{|p| p.first }

    def initialize(xml)
      if xml && ! xml.empty?
        info = PubMed::Article.parse_xml xml
        info.each do |key, value|
          self.send("#{ key }=", value)
        end
      end
    end

    def pdf_url
      return pmc_pdf if pmc_pdf
      @gscholar_pdf ||= begin
                          GoogleScholar::full_text_url title
                        rescue
                          Log.medium "GoogleScholar#full_text failed: #{title}"
                          sleep 0.1
                          nil
                        end
    end

    def full_text
      return nil if pdf_url.nil?

      text = nil
      TmpFile.with_file do |pdf|

        # Change user-agent, oh well...
        `wget --user-agent=firefox #{ pdf_url } -O #{ pdf } -t 3`
        TmpFile.with_file do |txt|
          `pdftotext #{ pdf } #{ txt }`
          text = Open.read(txt) if File.exists? txt
        end
      end

      Misc.fixutf8(text)
    end

    def bibtex
      keys = [:author] + XML_KEYS.collect{|p| p.first } - [:bibentry]
      bibtex = "@article{#{bibentry},\n"

      keys.each do |key|
        next if self.send(key).nil?

        case key

        when :title
          bibtex += "  title = { #{ PubMed::Article.escape_title title } },\n"

        when :issue
          bibtex += "  number = { #{ issue } },\n"

        else
          bibtex += "  #{ key } = { #{ self.send(key) } },\n"
        end

      end

      bibtex += "  fulltext = { #{ pdf_url } },\n" if pdf_url
      bibtex += "  pmid = { #{ pmid } }\n}"


      bibtex
    end

    # Join the text from title and abstract
    def text
      text = [title, abstract].join("\n")

      Misc.fixutf8(text)
    end
  end

  # Returns the Article object containing the information for the PubMed
  # ID specified as an argument. If +pmid+ is an array instead of a single
  # identifier it returns an hash with the Article object for each id.
  # It uses the Rbbt cache to save the articles xml.
  def self.get_article(pmid)

    if pmid.is_a? Array
      missing = []
      list = {}

      pmid.each{|p|
        filename = p.to_s + '.xml'
        if File.exists? FileCache.path(filename)
          list[p] = Article.new(Open.read(FileCache.path(filename)))
        else
          missing << p
        end
      }

      return list unless missing.any?

      articles = get_online(missing)

      articles.each{|p, xml|
        filename = p + '.xml'
        FileCache.add(filename,xml)
        list[p] =  Article.new(xml)
      }

      return list

    else
      filename = pmid.to_s + '.xml'

      if File.exists? FileCache.path(filename)
        return Article.new(Open.read(FileCache.path(filename)))
      else
        xml = get_online(pmid)
        FileCache.add(filename,xml)

        return Article.new(xml)
      end
    end
  end

  # Performs the specified query and returns an array with the PubMed
  # Ids returned. +retmax+ can be used to limit the number of ids
  # returned, if is not specified 30000 is used.
  def self.query(query, retmax=nil)
    retmax ||= 30000

    Open.read("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?retmax=#{retmax}&db=pubmed&term=#{query}",:quiet => true, :nocache => true).scan(/<Id>(\d+)<\/Id>/).flatten
  end
end
