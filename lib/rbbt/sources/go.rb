require 'rbbt-util'
require 'rbbt/resource'
require 'rbbt/persist/tsv'

# This module holds helper methods to deal with the Gene Ontology files. Right
# now all it does is provide a translation form id to the actual names.
module GO

  extend Resource
  
  extend Resource
  self.subdir = 'share/databases/GO'

  #Rbbt.claim Rbbt.share.databases.GO.gslim_generic, :url, 'http://www.geneontology.org/GO_slims/goslim_generic.obo'
  GO.claim GO.gene_ontology, :url, 'http://purl.obolibrary.org/obo/go.obo'
  GO.claim GO.Hsa.annotations, :url, 'http://geneontology.org/gene-associations/goa_human.gaf.gz'

  GO.claim GO.annotations, :url, 'http://geneontology.org/gene-associations/goa_human.gaf.gz'


  MULTIPLE_VALUE_FIELDS = %w(is_a)
  TSV_GENE_ONTOLOGY = File.join(Persist.cachedir, 'gene_ontology')

  # This method needs to be called before any translations can be made, it is
  # called automatically the first time the id2name method is called. It loads
  # the gene_ontology.obo file and extracts all the fields, although right now,
  # only the name field is used.
  def self.init
    Persist.persist_tsv(nil, 'gene_ontology', {}, :persist => true) do |info|
      info.serializer = :marshal if info.respond_to? :serializer
      Rbbt.share.databases.GO.gene_ontology.read.split(/\[Term\]/).each{|term| 
        term_info = {}

        term.split(/\n/). select{|l| l =~ /:/}.each{|l| 
          key, value = l.chomp.match(/(.*?):(.*)/).values_at(1,2)
          if MULTIPLE_VALUE_FIELDS.include? key.strip
            term_info[key.strip] ||= []
            term_info[key.strip] << value.strip
          else
            term_info[key.strip] = value.strip
          end
        }

        next if term_info["id"].nil?
        info[term_info["id"]] = term_info
      }

      info
    end.tap{|o| o.unnamed = true}
  end

  def self.info
    @@info ||= self.init
  end

  def self.goterms
    info.keys
  end

  def self.id2name(id)
    if id.kind_of? Array
      info.values_at(*id).collect{|i| i['name'] if i}
    else
      return nil if info[id].nil?
      info[id]['name']
    end
  end

  def self.descendants(id)
    list = Set.new
    new = Set.new
    new << id
    while new.any?
      list += new
      new = Set.new
      info.each do |new_id,values|
        next unless values['is_a']
        new << new_id if values['is_a'].select{|e| list.include? e.split("!").first[/GO:\d+/] }.any? && ! list.include?(new_id)
      end
    end
    list
  end

  def self.id2ancestors_by_type(id, type='is_a')
    if id.kind_of? Array
      info.values_at(*id).
        select{|i| ! i[type].nil?}.
        collect{|i| 
          res = i[type]
          res = [res] unless Array === res
          res.collect{|id| 
            id.match(/(GO:\d+)/)[1] if id.match(/(GO:\d+)/)
          }.compact
        }
    else
      return [] if id.nil? or info[id].nil? or info[id][type].nil?
      res = info[id][type]
      res = [res] unless Array === res
      res.
        collect{|id| 
        id.match(/(GO:\d+)/)[1] if id.match(/(GO:\d+)/)
      }.compact
    end
  end

  def self.id2ancestors(id)
    id2ancestors_by_type(id, 'is_a') + id2ancestors_by_type(id, 'relationship')
  end

  def self.id2namespace(id)
    self.init unless info
    if id.kind_of? Array
      info.values_at(*id).collect{|i| i['namespace'] if i}
    else
      return nil if info[id].nil?
      info[id]['namespace']
    end
  end

  def self.ancestors_in(term, valid = false)
    ancestors = id2ancestors(term)
    return ancestors if FalseClass === valid
    valid_ancestors = ancestors & valid
    return valid_ancestors if valid_ancestors.any?
    ancestors.inject([]) do |acc,ancestor|
      valid_a = ancestors_in ancestor, valid
      acc = acc + valid_a
    end.uniq
  end

  def self.group_genes(list, valid = nil)
    valid = %w(GO:0005886 GO:0005634 GO:0005730 GO:0005829) if valid.nil?

    compartment_leaves = {}
    list.zip(list.go_cc_terms).each do |gene,terms|
      terms = [] if terms.nil?
      valid_terms = terms & valid
      valid_terms = terms.collect{|term| 
        (valid.include?(term) ? term : ancestors_in(term, valid))
      }.flatten
      #valid_terms - GOTerm.setup(valid_terms).flat_ancestry.flatten
      valid_terms.each do |term|
        compartment_leaves[term] ||= []
        compartment_leaves[term].push(gene)
      end
    end

    groups = {}
    while compartment_leaves.length > 1
      # Group common
      group = false
      new_compartment_leaves = {}
      compartment_leaves.each do |c,l|
        if l.length > 1
          groups[c] = l
          group = true
          new_compartment_leaves[c] = [c]
        else
          new_compartment_leaves[c] = l
        end
      end
      compartment_leaves = new_compartment_leaves

      # Pull-up leaves
      if group == false
        new_compartment_leaves = {}
        final = compartment_leaves.keys
        compartment_leaves
        compartment_leaves.each do |c,l|
          final = final - GOTerm.setup(c.dup).flat_ancestry
        end

        compartment_leaves.each do |c,l|
          if final.include? c
            valid_an = ancestors_in c, valid
            valid_an.each do |ancestor|
              new_compartment_leaves[ancestor] ||= []
              new_compartment_leaves[ancestor].push(c)
              groups[ancestor].push(c) if groups[ancestor]
            end
          else
            new_compartment_leaves[c] = l
          end
        end
        compartment_leaves = new_compartment_leaves
      end
    end
    ng = {}
    groups.keys.reverse.each do |k|
      ng[k] = {items: groups[k].uniq, id: k, name: id2name(k)}
    end
    ng
  end
end

if defined? Entity 

  module GOTerm
    extend Entity
    self.format = "GO ID"

    self.annotation :organism

    property :name => :array2single do
      GO.id2name(self)
    end

    property :genes => :array2single do |*args|
      organism = args.first
      organism ||= self.organism
      res = Organism.gene_go(organism).tsv(:persist => true, :key_field => "GO ID", :fields => ["Ensembl Gene ID"], :type => :flat, :merge => true).values_at *self
      res.collect{|r| r.organism = organism if r and r.respond_to? :organism}
      res
    end

    property :description => :single2array do
      description = GO.info[self]['def']
      description.gsub!(/"|\[.*\]/,'') if description

      description
    end

    property :ancestors => :single2array do
      GOTerm.setup(GO.id2ancestors(self))
    end

    property :ancestor => :single2array do
      ancestors.first
    end

    property :ancestry => :single2array do
      ancestry = {}
      self.ancestors.each do |ancestor|
        prev = ancestor.ancestry
        ancestry[ancestor] = prev
      end
      ancestry
    end

    property :flat_ancestry => :single2array do
      ancestry = []
      self.ancestors.each do |ancestor|
        prev = ancestor.flat_ancestry
        ancestry = ancestry + [ancestor] + prev
      end
      ancestry
    end
  end

  if defined? Gene and Entity === Gene
    module Gene
      property :go_terms => :array2single do 
        @go_terms ||= Organism.gene_go(organism).tsv(:persist => true, :key_field => "Ensembl Gene ID", :fields => ["GO ID"], :type => :flat, :merge => true, :namespace => organism).chunked_values_at self.ensembl
      end

      property :go_bp_terms => :array2single do 
        @go_bp_terms ||= Organism.gene_go_bp(organism).tsv(:persist => true, :key_field => "Ensembl Gene ID", :fields => ["GO ID"], :type => :flat, :merge => true, :namespace => organism).chunked_values_at self.ensembl
      end

      property :go_cc_terms => :array2single do 
        @go_cc_terms ||= Organism.gene_go_cc(organism).tsv(:persist => true, :key_field => "Ensembl Gene ID", :fields => ["GO ID"], :type => :flat, :merge => true, :namespace => organism).chunked_values_at self.ensembl
      end

      property :go_mf_terms => :array2single do 
        @go_mf_terms ||= Organism.gene_go_mf(organism).tsv(:persist => true, :key_field => "Ensembl Gene ID", :fields => ["GO ID"], :type => :flat, :merge => true, :namespace => organism).chunked_values_at self.ensembl
      end

    end
  end
end


