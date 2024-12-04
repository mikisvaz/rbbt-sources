require 'rbbt/util/open'
require 'rbbt/sources/organism'
require 'rbbt/tsv'
require 'rbbt/sources/ensembl'
require 'net/ftp'

module Ensembl
  
  module FTP

    SERVER = "ftp.ensembl.org"
    DOMAIN_SERVER = "ftp.ensemblgenomes.org"

    def self.ftp_name_for_domain(domain, organism, subdir='mysql')
      code, build = organism.split "/"
      build ||= "current"

      release = build == "current" ? 'current' : Ensembl.releases[build]
      name = Organism.scientific_name(organism)
      ftp = Net::FTP.new(Ensembl::FTP::DOMAIN_SERVER)
      ftp.passive = true
      ftp.login
      dir = File.join('pub', domain,  'current', subdir)
      ftp.chdir(dir)
      file = ftp.list(name.downcase.gsub(" ",'_') + "*").reject{|f|  f.split("_").length > 3 && ! f.include?("_core_") }.reject{|f| f =~ /\.gz$/}.collect{|l| l.split(" ").last}.last
      ftp.close
      [release, File.join(Ensembl::FTP::DOMAIN_SERVER, dir, file)]
    end

    def self.ftp_name_for(organism, subdir='mysql')
      if domain = Thread.current["ensembl_domain"]
        return ftp_name_for_domain(domain, organism,subdir)
      end

      code, build = organism.split "/"
      build ||= "current"

      if build.to_s == "current"
        release = 'current'
        name = Organism.scientific_name(organism)
        ftp = Net::FTP.new(Ensembl::FTP::SERVER)
        ftp.passive = true
        ftp.login
        dir = File.join('pub', "current_#{subdir}")
        ftp.chdir(dir)
        file = ftp.list(name.downcase.gsub(" ",'_') + "*").reject{|f| f.split("_").length > 3 && ! f.include?("_core_") }.collect{|l| l.split(" ").last}.last
        ftp.close
      else
        release = Ensembl.releases[build]
        name = Organism.scientific_name(organism)
        ftp = Net::FTP.new(Ensembl::FTP::SERVER)
        ftp.passive = true
        ftp.login
        dir = File.join('pub', release, subdir)
        ftp.chdir(dir)
        file = ftp.list(name.downcase.gsub(" ",'_') + "_core_*").reject{|f| f =~ /\.gz$/}.collect{|l| l.split(" ").last}.last
        ftp.close
      end
      [release, File.join(Ensembl::FTP::SERVER, dir, file)]
    end

    def self.ftp_url_for(organism)
      release, ftp_url = ftp_name_for(organism)
      ftp_url
    end

    def self.base_url(organism)
      File.join("ftp://", ftp_url_for(organism) )
    end

    def self.url_for(organism, table, extension)
      File.join(base_url(organism), table) + ".#{extension}.gz"
    end

    def self._get_gz(url)
      begin
        CMD.cmd("wget '#{url}' -O  - | gunzip").read
      rescue
        CMD.cmd("wget '#{url}.bz2' -O  - | bunzip2 | gunzip").read
      end
    end

    def self._get_file(organism, table, extension)
      url = url_for(organism, table, extension)
      self._get_gz(url)
    end

    def self.has_table?(organism, table)
      sql_file = _get_file(organism, File.basename(base_url(organism)), 'sql')
      ! sql_file.match(/^CREATE TABLE .#{table}. \((.*?)^\)/sm).nil?
    end

    def self.fields_for(organism, table)
      sql_file = _get_file(organism, File.basename(base_url(organism)), 'sql')
      chunk = sql_file.match(/^CREATE TABLE .#{table}. \((.*?)^\)/sm)[1]
      chunk.scan(/^\s+`(.*?)`/).flatten
    end

    def self.ensembl_tsv(organism, table, key_field = nil, fields = nil, options = {})
      if key_field and fields
        all_fields = fields_for(organism, table)
        key_pos = all_fields.index key_field
        field_pos = fields.collect{|f| all_fields.index f}

        options[:key_field] = key_pos
        options[:fields]    = field_pos
      end

      tsv = TSV.open(StringIO.new(_get_file(organism, table, "txt")), options)
      tsv.key_field = key_field
      tsv.fields = fields
      tsv
    end
  end
end
