require 'rbbt-util'
require 'rbbt/resource'
require 'rest-client'

module Xena
  extend Resource
  self.subdir = 'share/databases/Xena'

  DEFAULT_XENA_HUB = "https://ucscpublic.xenahubs.net"
  TCGA_HUB = "https://tcga.xenahubs.net/"
  #def self.organism(org="Hsa")
  #  Organism.default_code(org)
  #end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib

  def self.query(query, hub = DEFAULT_XENA_HUB)
    url = File.join(hub, 'data/')
    
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    header = {'Content-Type': 'text/plain'}
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = query
    response = http.request(request)

    JSON.parse(response.body)
  end

  def self.tsv(file, hub = DEFAULT_XENA_HUB)
    url = "#{hub}/download/#{file}"
    TSV.open(url, :monitor => true, :header_hash => '')
  end

  def self.cohorts(hub = DEFAULT_XENA_HUB)
    query =<<-EOF
(;allCohorts
(fn []
  (map :cohort
    (query
      {:select [[#sql/call [:distinct #sql/call [:ifnull :cohort "(unassigned)"]] :cohort]]
      :from [:dataset]})))
)
    EOF

    self.query query, hub
  end

  def self.cohort_dataset(cohort, hub = DEFAULT_XENA_HUB)
    query =<<-EOF
(; datasetList
(fn [cohorts]
    (let [count-table {:select [[:dataset.name :dname] [:%count.value :count]]
                       :from [:dataset]
                       :join [:field [:= :dataset.id :dataset_id]
                       :code [:= :field.id :field_id]]
                       :group-by [:dataset.name]
                       :where [:= :field.name "sampleID"]}]
        (query {:select [:d.name :d.longtitle :count :d.type :d.datasubtype :d.probemap :d.text :d.status [:pm-dataset.text :pmtext]]
                   :from [[:dataset :d]]
                   :left-join [[:dataset :pm-dataset] [:= :pm-dataset.name :d.probemap]
                                count-table [:= :dname :d.name]]
                   :where [:in :d.cohort cohorts]})
))
 ["#{ cohort }"])
    EOF

    self.query(query, hub)
  end

  
  Xena.claim Xena.data, :proc do 
  end
end

if __FILE__ == $0

  Xena.cohorts(Xena::TCGA_HUB).each do |cohort|
    puts Log.color :magenta, cohort
    Xena.cohort_dataset(cohort, Xena::TCGA_HUB).each do |info|
      puts Log.color(:blue, "Name: ") + Log.color(:yellow, info["name"].to_s)
      puts Log.color(:blue, "Title: ") + info["longtitle"].to_s
      puts Log.color(:blue, "Type: ") + info["type"].to_s
      puts
    end
    puts
  end

  raise "STOP"

  query_str =<<-EOF
  (;allCohorts
  (fn []
    (map :cohort
        (query
             {:select [[#sql/call [:distinct #sql/call [:ifnull :cohort "(unassigned)"]] :cohort]]
             :from [:dataset]}))))
EOF

  Log.severity = 0
  iii Xena.query(query_str, 'https://ucscpublic.xenahubs.net/')
  raise "STOP"
  file = "GTEx_Analysis_v6_RNA-seq_RNA-SeQCv1.1.8_gene_rpkm_log.gz"
  Log.tsv Xena.tsv(file)
end

