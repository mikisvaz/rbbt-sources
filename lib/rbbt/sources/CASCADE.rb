require 'rbbt-util'
require 'rbbt/resource'

module CASCADE
  extend Resource
  self.subdir = 'share/databases/CASCADE'

  #def self.organism(org="Hsa")
  #  Organism.default_code(org)
  #end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib

  def self.process_interactions(file)
    io = Open.open(file)
    tsv = TSV.open(io, :merge => true, :header_hash => '')

    new_fields = ["ENTITYB"] + (tsv.fields - ["ENTITYB"])
    tsv = tsv.reorder :key, new_fields

    tsv.key_field = "ENTITYA (Associated Gene Name)"
    tsv.rename_field "ENTITYB", "ENTITYB (Associated Gene Name)"

    tsv.process "PMID" do |values|
      values.collect{|v| v.scan(/\d+/) * ";;"}
    end

    tsv
  end

  def self.process_members(file)
    TSV.open(file, :merge => true, :header_hash => '', :type => :flat, :sep2 => /[,.]\s*/)
  end

  def self.process_paradigm(interactions, members)
    proteins = Set.new members.values.flatten.uniq
    outputs = Set.new
    associations = {}

    interactions.through do |source, values|
      Misc.zip_fields(values.values_at("ENTITYB", "TYPEA", "IDA","DATABASEA", "TYPEB", "IDB", "DATABASEB", "EFFECT")).each do |target,typea,ida,databasea,typeb,idb,databaseb,effect|
        next if typea == 'gene'
        typea.strip!
        typeb.strip!

        typea = 'output' if typea == 'phenotype'
        typeb = 'output' if typeb == 'phenotype'

        if typeb == 'gene'
          target.sub!('_g','')
          type = '-t'
        elsif typeb == 'output' or typea == 'output'
          type = '-ap'
        elsif typeb == 'protein' or typeb == 'protein family' or typeb == 'protein complex' or typeb == 'second messenger'
          type = '-a'
        else 
          raise "Unknown type #{typeb} #{source} #{target}"
        end

        proteins << source unless source.include? '_f' or source.include? '_c'
        proteins << target unless target.include? '_f' or target.include? '_c'

        outputs << source if typea == 'output'
        outputs << target if typeb == 'output'

        effect_symbol = '>' 
        effect_symbol = '|' if effect.include? 'inhibit'

        associations[[source,target]] = [type, effect_symbol]
      end
    end

    str = StringIO.new

    proteins.each do |p|
      next if outputs.include? p
      str.puts ["protein", p] * "\t"
    end

    outputs.each do |o|
      str.puts ["abstract", o] * "\t"
    end

    members.each do |e, targets|
      e = e.dup
      case 
      when e.include?('_c')
        str.puts ["complex", e] * "\t"
        type = 'component'
      when e.include?('_f')
        str.puts ["family", e] * "\t"
        type = 'member'
      else
        next
      end

      targets.each do |target|
        associations[[target,e]] = [type, '>']
      end
    end

    associations.each do |p,i|
      source, target = p
      type, symbol = i

      str.puts [source, target, [type,symbol]*""] * "\t"
    end

    str.rewind
    str
  end


  URL = 'https://bitbucket.org/asmundf/cascade'
  CASCADE.claim CASCADE.interactions, :proc do 
    io = nil
    TmpFile.with_file do |tmp|
      Misc.in_dir tmp do
        Log.warn "Please enter bitbucket credentials to access the asmundf/cascade repo"
        `git clone #{URL}`
        process_interactions("cascade/cascade.tsv")
      end
    end
  end

  CASCADE.claim CASCADE.members, :proc do 
    TmpFile.with_file do |tmp|
      Misc.in_dir tmp do
        Log.warn "Please enter bitbucket credentials to access the asmundf/cascade repo"
        `git clone #{URL}`
        process_members("cascade/cascade_translation.tsv")
      end
    end
  end

  CASCADE.claim CASCADE.paradigm, :proc do

    interactions = CASCADE.interactions.tsv 
    members = CASCADE.members.tsv 

    process_paradigm(interactions, members)
  end

  CASCADE.claim CASCADE.output_nodes, :proc do
    tsv = CASCADE.interactions.tsv 

    output = TSV.setup({}, :key_field => "Node", :fields => ["Sign"], :type => :single)

    tsv.through do |source, values|
      values.zip_fields.each do |target,typea,ida,databasea,typeb,idb,databaseb,effect|
        case target
        when "Antisurvival"
          output[source] = -1
        when "Prosurvival"
          output[source] = 1
        end
      end
    end

    output.to_s
  end
end

iif CASCADE.interactions.produce.find if __FILE__ == $0
iif CASCADE.members.produce.find if __FILE__ == $0
iif CASCADE.paradigm.produce.find if __FILE__ == $0
iif CASCADE["topology.sif"].produce.find if __FILE__ == $0
iif CASCADE.output_nodes.produce.find if __FILE__ == $0

