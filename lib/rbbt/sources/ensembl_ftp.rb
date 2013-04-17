require 'rbbt/util/open'
require 'rbbt/sources/organism'
require 'rbbt/tsv'
require 'rbbt/sources/ensembl'
require 'net/ftp'

module Ensembl
  
  module FTP

    SERVER = "ftp.ensembl.org"

    def self.ftp_name_for(organism)
      code, build = organism.split "/"
      build ||= "current"

      if build.to_s == "current"
      else
        release = Ensembl.releases[build]
        name = Organism.scientific_name(organism)
        ftp = Net::FTP.new(Ensembl::FTP::SERVER)
        ftp.passive = true
        ftp.login
        ftp.chdir(File.join('pub', release, 'mysql'))
        file = ftp.list(name.downcase.gsub(" ",'_') + "_core_*").collect{|l| l.split(" ").last}.last
        ftp.close
      end
      [release, file]
    end

    def self.ftp_directory_for(organism)
      release, ftp_name = ftp_name_for(organism)
      File.join('/pub/', release, 'mysql', ftp_name)
    end

    def self.base_url(organism)
      File.join("ftp://" + SERVER, ftp_directory_for(organism) )
    end

    def self.url_for(organism, table)
      "#{base_url(organism)}/#{table}.txt.gz"
    end

    def self.has_table?(organism, table)
      sql_file = Open.read("#{base_url(organism)}/#{File.basename(base_url(organism))}.sql.gz")
      ! sql_file.match(/^CREATE TABLE .#{table}. \((.*?)^\)/sm).nil?
    end

    def self.fields_for(organism, table)
      sql_file = Open.read("#{base_url(organism)}/#{File.basename(base_url(organism))}.sql.gz")

      chunk = sql_file.match(/^CREATE TABLE .#{table}. \((.*?)^\)/sm)[1]
      chunk.scan(/^\s+`(.*?)`/).flatten
    end

    def self.ensembl_tsv(organism, table, key_field = nil, fields = nil, options = {})
      url = url_for(organism, table)
      if key_field and fields
        all_fields = fields_for(organism, table)
        key_pos = all_fields.index key_field
        field_pos = fields.collect{|f| all_fields.index f}

        options[:key_field] = key_pos
        options[:fields]    = field_pos
      end
      tsv = TSV.open(url, options)
      tsv.key_field = key_field
      tsv.fields = fields
      tsv
    end
  end
end

if __FILE__ == $0
  ddd Ensembl::FTP.ensembl_tsv("Hsa/may2012", 'exon')
end
