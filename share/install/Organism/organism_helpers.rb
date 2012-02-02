require 'net/ftp'

$biomart_ensembl_gene = ['Ensembl Gene ID', 'ensembl_gene_id']
$biomart_ensembl_protein = ['Ensembl Protein ID', 'ensembl_peptide_id']
$biomart_ensembl_exon = ['Ensembl Exon ID', 'ensembl_exon_id']
$biomart_ensembl_transcript = ['Ensembl Transcript ID', 'ensembl_transcript_id']

$biomart_gene_positions = [
  ['Chromosome Name','chromosome_name'],
  ['Strand','strand'],
  ['Gene Start','start_position'],
  ['Gene End','end_position'],
]

$biomart_gene_sequence = [
  ['Gene Sequence','gene_exon_intron'],
]

#{{{ Transcript

$biomart_gene_transcript = [
  $biomart_ensembl_transcript
]

$biomart_transcript = [
  ['Transcript Start (bp)','transcript_start'],
  ['Transcript End (bp)','transcript_end'],
  $biomart_ensembl_protein,
  $biomart_ensembl_gene
]

$biomart_transcript_sequence = [
  ['cDNA','cdna'],
]

$biomart_transcript_3utr = [
  ["3' UTR", '3utr'],
]

$biomart_transcript_5utr = [
  ["5' UTR", '5utr'],
]


$biomart_protein_sequence = [
  ['Protein Sequence','peptide'],
]

#{{{ Exons

$biomart_transcript_exons = [
  $biomart_ensembl_exon,
  ['Exon Rank in Transcript','rank'],
]

$biomart_exon_phase = [
  $biomart_ensembl_transcript,
  ['Phase','phase'],
]

$biomart_pfam= [
  ["Pfam Domain", 'pfam'],
]

$biomart_exons = [
  $biomart_ensembl_gene,
  ['Exon Strand','strand'],
  ['Exon Chr Start','exon_chrom_start'],
  ['Exon Chr End','exon_chrom_end'],
]

#{{{ Rules

file 'entrez_taxids' do |t|
  File.open(t.name, 'w') do |f| f.write $taxs * "\n" end
end

file 'scientific_name' do |t|
  File.open(t.name, 'w') do |f| f.write $scientific_name end
end

file 'ortholog_key' do |t|
  raise "Ortholog key not defined. Set up $ortholog_key in the organism specific Rakefile; example $ortholog_key = 'human_ensembl_gene'" unless defined? $ortholog_key and not $ortholog_key.nil?

  File.open(t.name, 'w') do |f| f.write $ortholog_key end
end

file 'identifiers' do |t|
  identifiers = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_identifiers, [], nil, :namespace => $namespace)
  identifiers.unnamed =  true

  $biomart_identifiers.each do |name, key, prefix|
    next unless identifiers.all_fields.include? name
    if prefix
      identifiers.process name do |field, key, values| field.each{|v| v.replace "#{prefix}:#{v}"} end
    end
  end

  name_pos = identifiers.identify_field "Associated Gene Name"
  entrez2name = Entrez.entrez2name($taxs)
  identifiers.process "Entrez Gene ID" do |entrez, ensembl, values|
    names = values[name_pos]

    matches = entrez.select do |e|
      entrez2name.include? e and (names & entrez2name[e]).any?
    end

    if matches.any?
      matches
    else
      entrez
    end
  end

  entrez_synonyms = Rbbt.share.databases.entrez.gene_info.tsv :grep => $taxs.collect{|tax| "^#{tax}"}, :key_field => 1, :fields => 4
  entrez_synonyms.key_field = "Entrez Gene ID"
  entrez_synonyms.fields = ["Entrez Gene Name Synonyms"]

  identifiers.attach entrez_synonyms
  

  identifiers.with_unnamed do
    identifiers.each do |key, values|
      values.each do |list|
        list.reject!{|v| v.nil? or v.empty?}
        list.uniq!
      end
    end
  end

  File.open(t.name, 'w') do |f| f.puts identifiers end
end

file 'lexicon' => 'identifiers' do |t|
  tsv = TSV.open(t.prerequisites.first).slice(["Associated Gene Name", "Entrez Gene Name Synonyms"])

  entrez_description = Rbbt.share.databases.entrez.gene_info.tsv :grep => $taxs.collect{|tax| "^#{tax}"}, :key_field => 1, :fields => 8
  entrez_description.key_field = "Entrez Gene ID"
  entrez_description.fields = ["Entrez Gene Description"]

  tsv.attach entrez_description
  Open.write(t.name, tsv.to_s)
end


file 'protein_identifiers' do |t|
  identifiers = BioMart.tsv($biomart_db, $biomart_ensembl_protein, $biomart_protein_identifiers, [], nil, :namespace => $namespace)
  $biomart_protein_identifiers.each do |name, key, prefix|
    if prefix
      identifiers.process name do |field, key, values| field.each{|v| v.replace "#{prefix}:#{v}"} end
    end
  end

  File.open(t.name, 'w') do |f| f.puts identifiers end
end

file 'transcript_probes' do |t|
  identifiers = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_probe_identifiers, [], nil, :namespace => $namespace)
  $biomart_probe_identifiers.each do |name, key, prefix|
    if prefix
      identifiers.process name do |field, key, values| field.each{|v| v.replace "#{prefix}:#{v}"} end
    end
  end

  File.open(t.name, 'w') do |f| f.puts identifiers end
end

file 'gene_transcripts' do |t|
  transcripts = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_transcript, [], nil, :type => :flat, :namespace => $namespace)

  File.open(t.name, 'w') do |f| f.puts transcripts end
end

file 'transcripts' => 'gene_positions' do |t|
  transcripts = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript, [], nil, :type => :list, :namespace => $namespace)
  transcripts.attach TSV.open('gene_positions'), :fields => ["Chromosome Name"]

  File.open(t.name, 'w') do |f| f.puts transcripts end
end

file 'transcript_3utr' do |t|
  utrs = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_3utr, [], nil, :type => :flat, :namespace => $namespace)

  File.open(t.name, 'w') do |f| 
    f.puts "#: :type=:single#cast=to_i"
    f.puts "#Ensembl Transcript ID\t3' UTR Length"
    utrs.each do |seq,trans|
      trans.each do |tran|
        f.puts [tran, seq.length] * "\t" if seq =~ /^[ACTG]+$/
      end
    end
  end
end

file 'transcript_5utr' do |t|
  utrs = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_5utr, [], nil, :type => :flat, :namespace => $namespace)

  File.open(t.name, 'w') do |f| 
    f.puts "#: :type=:single#cast=to_i"
    f.puts "#Ensembl Transcript ID\t5' UTR Length"
    utrs.each do |seq,trans|
      trans.each do |tran|
        f.puts [tran, seq.length] * "\t" if seq =~ /^[ACTG]+$/
      end
    end
  end
end

file 'gene_positions' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_positions, [])

  File.open(t.name, 'w') do |f| f.puts sequences end
end

file 'gene_sequence' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_sequence, [], nil, :type => :flat, :namespace => $namespace)

  File.open(t.name, 'w') do |f| 
    f.puts "#: :type=:single"
    f.puts "#Ensembl Gene ID\tGene Sequence"
    sequences.each do |seq, genes|
      genes.each do |gene|
        f.write gene 
        f.write "\t" 
        f.write seq
        f.write "\n"
      end
    end
  end
end

file 'protein_sequence' => 'chromosomes' do |t|
  #chromosomes = TSV.open(t.prerequisites.first).keys
  #sequences = BioMart.tsv($biomart_db, $biomart_ensembl_protein, $biomart_protein_sequence, [], nil, :type => :flat, :namespace => $namespace, :chunk_filter => ['chromosome_name', chromosomes])
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_protein, $biomart_protein_sequence, [], nil, :type => :flat, :namespace => $namespace)

  File.open(t.name, 'w') do |f| 
    f.puts "#: :type=:single"
    f.puts "#Ensembl Protein ID\tProtein Sequence"
    sequences.each do |seq, genes|
      genes.each do |gene|
        f.write gene 
        f.write "\t" 
        f.write seq
        f.write "\n"
      end
    end
  end
end

file 'exons' => 'gene_positions' do |t|
  exons = BioMart.tsv($biomart_db, $biomart_ensembl_exon, $biomart_exons, [], nil, :merge => false, :type => :list, :namespace => $namespace)
  exons.attach TSV.open('gene_positions'), :fields => ["Chromosome Name"]

  File.open(t.name, 'w') do |f| f.puts exons end
end

file 'transcript_exons' do |t|
  exons = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_exons, [], nil, :keep_empty => true, :namespace => $namespace)

  File.open(t.name, 'w') do |f| f.puts exons end
end

file 'exon_phase' do |t|
  exons = BioMart.tsv($biomart_db, $biomart_ensembl_exon, $biomart_exon_phase, [], nil, :keep_empty => true, :namespace => $namespace)

  File.open(t.name, 'w') do |f| f.puts exons end
end


#file 'transcript_phase' do |t|
#  tsv = TSV.setup({}, :key_field => "Ensembl Transcript ID", :fields => ["Phase"], :type => :single, :cast => :to_i)
#
#  transcript_cds_start = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, [['CDNA Start','cds_start']], [], nil, :type => :flat, :namespace => $namespace)
#  transcript_cds_start.through do |transcript, values|
#    phase = values.compact.reject{|p| p.empty?}.select{|p| p == "1" or p == "2"}.first
#    tsv[transcript] = phase.to_i unless phase.nil?
#  end
#
#  File.open(t.name, 'w') do |f| f.puts tsv end
#end

file 'transcript_phase' => ['exon_phase', 'transcript_exons'] do |t|
  tsv = TSV.setup({}, :key_field => "Ensembl Transcript ID", :fields => ["phase"], :type => :single, :cast => :to_i)

  transcript_exons = TSV.open(t.prerequisites.last)
  transcript_exons.unnamed = true

  exon_is_first_for_transcripts = {}

  transcript_exons.through do |transcript, value|
    exon = Misc.zip_fields(value).select{|exon, rank| rank == "1" }.first[0]
    exon_is_first_for_transcripts[exon] ||=  []
    exon_is_first_for_transcripts[exon] << transcript
  end

  exon_phase = TSV.open(t.prerequisites.first)
  exon_phase.unnamed = true
  exon_phase.monitor = true

  exon_phase.through do |exon, value|
    Misc.zip_fields(value).each{|transcript, phase| 
      next unless exon_is_first_for_transcripts.include? exon
      next unless exon_is_first_for_transcripts[exon].include? transcript
      tsv[transcript] = phase  
    }
  end

  File.open(t.name, 'w') do |f| f.puts tsv end
end


file 'transcript_sequence' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_sequence, [], nil, :type => :flat, :namespace => $namespace)

  File.open(t.name, 'w') do |f| 
    f.puts "#: :type=:single"
    f.puts "#Ensembl Transcript ID\tTranscript Sequence"
    sequences.each do |seq, genes|
      genes.each do |gene|
        f.write gene 
        f.write "\t" 
        f.write seq
        f.write "\n"
      end
    end
  end
end


#{{{ Variations

$biomart_variation_id = ["SNP ID", "refsnp_id"]
$biomart_variation_position = [["Chromosome Name", "chr_name"], ["Chromosome Start", "chrom_start"]]

file 'germline_variations' do |t|
  BioMart.tsv($biomart_db_germline_variation, $biomart_variation_id, $biomart_variation_position, [], nil, :keep_empty => true, :type => :list, :filename => t.name, :namespace => $namespace)
end

file 'somatic_variations' do |t|
  BioMart.tsv($biomart_db_somatic_variation, $biomart_variation_id, $biomart_variation_position, [], nil, :keep_empty => true, :type => :list, :filename => t.name, :namespace => $namespace)
end


# {{{ Other info

file 'gene_pmids' do |t|
  tsv =  Entrez.entrez2pubmed($taxs)
  text = "#: :namespace=#{$namespace}\n"
  text += "#Entrez Gene ID\tPMID"
  tsv.each do |gene, pmids|
    text << "\n" << gene << "\t" << pmids * "|"
  end
  Open.write(t.name, text)
end

def coding_transcripts_for_exon(exon, exon_transcripts, transcript_info) 
  transcripts = begin
                  exon_transcripts[exon].first
                rescue
                  []
                end

  transcripts.select{|transcript| transcript_info[transcript].first.any?}
end

def exon_offset_in_transcript(exon, transcript, exons, transcript_exons)
  sizes = [0]
  rank = nil
  start_pos = exons.identify_field "Exon Chr Start"
  end_pos = exons.identify_field "Exon Chr End"

  Misc.zip_fields(transcript_exons[transcript]).each do |_exon, _rank|
    _rank = _rank.to_i
    s, e = exons[_exon].values_at(start_pos, end_pos)
    size = e.to_i - s.to_i + 1 
    sizes[_rank] =  size
    rank = _rank if _exon == exon
  end

  if not rank.nil?
    sizes[0..rank - 1].inject(0){|e,acc| acc += e}
  else
    nil
  end
end

file 'exon_offsets' => %w(exons transcript_exons gene_transcripts transcripts transcript_exons) do |t|
  exons = TSV.open('exons')
  exon_transcripts = nil
  exon_transcripts = TSV.open('transcript_exons', :double, :key_field => "Ensembl Exon ID", :fields => ["Ensembl Transcript ID"], :merge => true)
  gene_transcripts = TSV.open('gene_transcripts', :flat)
  transcript_info  = TSV.open('transcripts', :list, :fields => ["Ensembl Protein ID"])
  transcript_exons = TSV.open('transcript_exons', :double, :fields => ["Ensembl Exon ID","Exon Rank in Transcript"])

  string = "#: :namespace=#{$namespace}\n"
  string += "#Ensembl Exon ID\tEnsembl Transcript ID\tOffset\n"

  exons.unnamed = true
  exon_transcripts.unnamed = true
  gene_transcripts.unnamed = true
  transcript_info.unnamed = true
  transcript_exons.unnamed = true

  exons.monitor = true
  exons.through do |exon, info|
    gene, start, finish, strand, chr = info

    transcripts = coding_transcripts_for_exon(exon, exon_transcripts, transcript_info)

    transcript_offsets = {}
    transcripts.each do |transcript|
      offset = exon_offset_in_transcript( exon, transcript, exons, transcript_exons)
      transcript_offsets[transcript] = offset unless offset.nil?
    end

    string << exon << "\t" << transcript_offsets.keys * "|" << "\t" << transcript_offsets.values * "|" << "\n"
  end

  Open.write(t.name, string)
end

file 'gene_go' do |t|
  if File.basename(FileUtils.pwd) =~ /^[a-z]{3}([0-9]{4})$/i and $1.to_i <= 2009
    goterms = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_go_2009, [], nil, :type => :double, :namespace => $namespace)

    goterms.add_field "GO ID" do |key, values|
      values.flatten.compact.reject{|go| go.empty?}
    end

    goterms.add_field "GO Namespace" do |key, values|
      ["biological_process"] * values["GO BP ID"].reject{|go| go.empty?}.length +
        ["cellular_component"] * values["GO CC ID"].reject{|go| go.empty?}.length +
        ["molecular_function"] * values["GO MF ID"].reject{|go| go.empty?}.length 
    end

    File.open(t.name, 'w') do |f| f.puts goterms.slice(["GO ID", "GO Namespace"]) end
  else
    goterms = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_go, [], nil, :type => :double, :namespace => $namespace)

    File.open(t.name, 'w') do |f| f.puts goterms end
  end
end

file 'gene_go_bp' => 'gene_go' do |t|
  gene_go = TSV.open(t.prerequisites.first)
   
  gene_go.monitor = true
  gene_go.process "GO ID" do |key, go_id, values|
    clean = values.zip_fields.select do |id, type|
      type == "biological_process"
    end
    clean.collect{|id, type| id}
  end


  File.open(t.name, 'w') do |f| f.puts gene_go.slice "GO ID" end
end

file 'gene_go_cc' => 'gene_go' do |t|
  gene_go = TSV.open(t.prerequisites.first)
   
  gene_go.monitor = true
  gene_go.process "GO ID" do |key, go_id, values|
    clean = values.zip_fields.select do |id, type|
      type == "cellular_component"
    end
    clean.collect{|id, type| id}
  end


  File.open(t.name, 'w') do |f| f.puts gene_go.slice "GO ID" end
end

file 'gene_go_mf' => 'gene_go' do |t|
  gene_go = TSV.open(t.prerequisites.first)
   
  gene_go.monitor = true
  gene_go.process "GO ID" do |key, go_id, values|
    clean = values.zip_fields.select do |id, type|
      type == "molecular_function"
    end
    clean.collect{|id, type| id}
  end


  File.open(t.name, 'w') do |f| f.puts gene_go.slice "GO ID" end
end




file 'gene_pfam' do |t|
  pfam = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_pfam, [], nil, :type => :double, :namespace => $namespace)

  File.open(t.name, 'w') do |f| f.puts pfam end
end

file 'chromosomes' do |t|
  goterms = BioMart.tsv($biomart_db, ['Chromosome Name', "chromosome_name"] , [] , [], nil, :type => :double, :namespace => $namespace)

  File.open(t.name, 'w') do |f| f.puts goterms end
end

rule /^chromosome_.*/ do |t|
  chr = t.name.match(/chromosome_(.*)/)[1]

  archive = File.basename(FileUtils.pwd) =~ /^([a-z]{3}[0-9]{4})$/i ? $1 : nil

  release = case archive
            when "may2009"
              "release-54"
            when "jun2011"
              "release-64"
            when nil
              Open.read("http://www.ensembl.org/info/data/ftp/index.html", :nocache => true).match(/pub\/(\w+-\d+)\/fasta/)[1]
            end


  ftp = Net::FTP.new("ftp.ensembl.org")
  ftp.login
  ftp.chdir("pub/#{ release }/fasta/")
  ftp.chdir($scientific_name.downcase.sub(" ",'_'))
  ftp.chdir('dna')
  file = ftp.nlst.select{|file| file =~ /chromosome\.#{ chr }\.fa/}.first

  raise "Fasta file for chromosome not found: #{ chr } - #{ archive }, #{ release }" if file.nil?

  Log.debug("Downloading chromosome sequence: #{ file }")

  Misc.lock t.name + '.rake' do
    TmpFile.with_file do |tmpfile|
      ftp.getbinaryfile(file, tmpfile)
      Open.write(t.name, Open.read(tmpfile, :gzip => true).sub(/^>.*\n/,'').gsub(/\s/,''))
      ftp.close
    end
  end
end

rule /^possible_ortholog_(.*)/ do |t|
  other = t.name.match(/ortholog_(.*)/)[1]
  other_key = Organism.ortholog_key(other).produce.read
  BioMart.tsv($biomart_db, $biomart_ensembl_gene, [["Ortholog Ensembl Gene ID", "inter_paralog_" + other_key]], [], nil, :keep_empty => false, :type => :flat, :filename => t.name, :namespace => $namespace)
end

rule /^ortholog_(.*)/ do |t|
  other = t.name.match(/ortholog_(.*)/)[1]
  other_key = Organism.ortholog_key(other).produce.read
  BioMart.tsv($biomart_db, $biomart_ensembl_gene, [["Ortholog Ensembl Gene ID", other_key]], [], nil, :keep_empty => false, :type => :flat, :filename => t.name, :namespace => $namespace)
end

rule /[a-z]{3}[0-9]{4}\/.*/i do |t|
  t.name =~ /([a-z]{3}[0-9]{4})\/(.*)/i
  archive = $1
  task    = $2
  Misc.in_dir(archive) do
    BioMart.set_archive archive
    Rake::Task[task].invoke
    BioMart.unset_archive 
  end
end
