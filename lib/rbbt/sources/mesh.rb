require 'rbbt-util'
require 'rbbt/resource'

module MeSH
  extend Resource

  self.subdir = "share/databases/MeSH"

  MeSH.claim MeSH["data.gz"], :url, "https://nlmpubs.nlm.nih.gov/projects/mesh/rdf/mesh.nt.gz"

  MeSH.claim MeSH.vocabulary, :proc do
    dumper = TSV::Dumper.new :key_field => "MeSH ID", :fields => ["Label"], :type => :single
    dumper.init
    TSV.traverse MeSH.data, :type => :array, :into => dumper, :bar => "Processing MeSH vocab" do |line|
      sub, verb, obj = line.split("\t")

      next unless verb && verb.include?("rdf-schema#label")

      id = sub.split("/").last[0..-2]
      label = obj.split('"')[1]

      [id, label]
    end
  end

end
