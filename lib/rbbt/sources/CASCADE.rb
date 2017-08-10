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


  URL = 'https://bitbucket.org/asmundf/cascade'
  CASCADE.claim CASCADE.interactions, :proc do 
    io = nil
    TmpFile.with_file do |tmp|
      Misc.in_dir tmp do
        Log.warn "Please enter bitbucket credentials to access the asmundf/cascade repo"
        `git clone #{URL}`
        io = Open.open("cascade/cascade.tsv")
      end
    end

    tsv = TSV.open(io, :merge => true, :header_hash => '')

    new_fields = ["ENTITYB"] + (tsv.fields - ["ENTITYB"])
    tsv = tsv.reorder :key, new_fields

    tsv.key_field = "ENTITYA (Associated Gene Name)"
    tsv.rename_field "ENTITYB", "ENTITYB (Associated Gene Name)"

    tsv.process "PMID" do |values|
      values.collect{|v| v.scan(/\d+/) * ";;"}
    end

    tsv.to_s
  end

  CASCADE.claim CASCADE.members, :proc do 
    io = nil
    TmpFile.with_file do |tmp|
      Misc.in_dir tmp do
        Log.warn "Please enter bitbucket credentials to access the asmundf/cascade repo"
        `git clone #{URL}`
        io = Open.open("cascade/cascade_translation.tsv")
      end
    end

    tsv = TSV.open(io, :merge => true, :header_hash => '', :type => :flat, :sep2 => /[,.]\s*/)

  end

  CASCADE.claim CASCADE.paradigm, :proc do

    tsv = CASCADE.interactions.tsv 
    members = CASCADE.members.tsv 

    proteins = Set.new members.values.flatten.uniq
    outputs = Set.new
    associations = {}

    tsv.through do |source, values|
      values.zip_fields.each do |target,typea,ida,databasea,typeb,idb,databaseb,effect|
        next if typea == 'gene'

        if typeb == 'gene'
          target.sub!('_g','')
          type = '-t'
        elsif typeb == 'output' or typea == 'output'
          type = '-ap'
        else
          type = '-a'
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

  CASCADE.claim CASCADE["topology.sif"], :proc do

    tsv = CASCADE.interactions.tsv 

    str = StringIO.new

    tsv.through do |source, values|
      values.zip_fields.each do |target,typea,ida,databasea,typeb,idb,databaseb,effect|

        effect_symbol = '->' 
        effect_symbol = '-|' if effect.include? 'inhibit' 

        str.puts [source, effect_symbol, target] * " "
      end
    end

    str.rewind
    str
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
iif CASCADE.output_nodes.produce(true).find if __FILE__ == $0

