require 'net/ftp'
require 'rbbt/sources/ensembl_ftp'

#Thread.current['namespace'] = $namespace

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

$biomart_transcript_cds = [
  ['CDS Start','cdna_coding_start'],
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

$biomart_transcript_biotype = [
  ["Ensembl Transcript Biotype", 'transcript_biotype'],
]

$biomart_transcript_name = [
  ["Ensembl Transcript Name", 'external_transcript_id'],
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

$biomart_gene_biotype= [
  ["Biotype", 'gene_biotype'],
]

$biomart_exons = [
  $biomart_ensembl_gene,
  ['Exon Strand','strand'],
  ['Exon Chr Start','exon_chrom_start'],
  ['Exon Chr End','exon_chrom_end'],
]

#{{{ Rules

file 'entrez_taxids' do |t|
  Misc.sensiblewrite(t.name, $taxs * "\n")
end

file 'scientific_name' do |t|
  Misc.sensiblewrite(t.name, $scientific_name)
end

file 'ortholog_key' do |t|
  raise "Ortholog key not defined. Set up $ortholog_key in the organism specific Rakefile; example $ortholog_key = 'human_ensembl_gene'" unless defined? $ortholog_key and not $ortholog_key.nil?

  Misc.sensiblewrite(t.name, $ortholog_key)
end

file 'identifiers' do |t|
  identifiers = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_identifiers, [], nil, :namespace => Thread.current['namespace'])
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

  refseq_fields = identifiers.fields.select{|f| f =~ /RefSeq/}

  if refseq_fields.any?
    refseq_pos = refseq_fields.collect{|refseq_field| identifiers.identify_field refseq_field }
    identifiers = identifiers.add_field "RefSeq ID" do |key,values|
      refseq_ids = values.values_at *refseq_pos
      refseq_ids.flatten.compact.reject{|v| v.empty?}
    end

    ordered_fields = identifiers.fields - ["RefSeq ID"]
    pos = ordered_fields.index ordered_fields.select{|f| f =~ /RefSeq/}.first
    ordered_fields[pos..pos-1] = "RefSeq ID"

    identifiers = identifiers.reorder(:key, ordered_fields)
  end

  entrez_synonyms = Rbbt.share.databases.entrez.gene_info.find.tsv :grep => $taxs.collect{|tax| "^#{tax}"}, :key_field => 1, :fields => [4]
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


  Misc.sensiblewrite(t.name, identifiers.to_s)
end

file 'lexicon' => 'identifiers' do |t|
  tsv = TSV.open(t.prerequisites.first).slice(["Associated Gene Name", "Entrez Gene Name Synonyms"])

  entrez_description = Rbbt.share.databases.entrez.gene_info.tsv :grep => $taxs.collect{|tax| "^#{tax}"}, :key_field => 1, :fields => 8
  entrez_description.key_field = "Entrez Gene ID"
  entrez_description.fields = ["Entrez Gene Description"]

  tsv.attach entrez_description
  Misc.sensiblewrite(t.name, tsv.to_s)
end


file 'protein_identifiers' do |t|
  identifiers = BioMart.tsv($biomart_db, $biomart_ensembl_protein, $biomart_protein_identifiers, [], nil, :namespace => Thread.current['namespace'])
  $biomart_protein_identifiers.each do |name, key, prefix|
    if prefix
      identifiers.process name do |field, key, values| field.each{|v| v.replace "#{prefix}:#{v}"} end
    end
  end

  Misc.sensiblewrite(t.name, identifiers.to_s)
end

file 'transcript_probes' do |t|
  identifiers = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_probe_identifiers, [], nil, :namespace => Thread.current['namespace'])
  $biomart_probe_identifiers.each do |name, key, prefix|
    if prefix
      identifiers.process name do |field, key, values| field.each{|v| v.replace "#{prefix}:#{v}"} end
    end
  end

  Misc.sensiblewrite(t.name, identifiers.to_s)
end

file 'gene_transcripts' do |t|
  transcripts = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_transcript, [], nil, :type => :flat, :namespace => Thread.current['namespace'])

  Misc.sensiblewrite(t.name, transcripts.to_s)
end

file 'transcripts' => 'gene_positions' do |t|
  transcripts = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript, [], nil, :type => :list, :namespace => Thread.current['namespace'])
  transcripts.attach TSV.open('gene_positions'), :fields => ["Chromosome Name"]

  Misc.sensiblewrite(t.name, transcripts.to_s)
end

file 'transcript_cds' do |t|
  cds = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_cds, [], nil, :type => :single, :namespace => Thread.current['namespace'], :cast => :to_i)

  Misc.sensiblewrite(t.name, cds.to_s)
end

file 'gene_positions' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_positions, [])

  Misc.sensiblewrite(t.name, sequences.to_s)
end

file 'gene_sequence' do |t|
  sequences = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_sequence, [], nil, :type => :flat, :namespace => Thread.current['namespace'])

  Misc.sensiblewrite(t.name) do |f|
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

file 'exons' => 'gene_positions' do |t|
  exons = BioMart.tsv($biomart_db, $biomart_ensembl_exon, $biomart_exons, [], nil, :merge => false, :type => :list, :namespace => Thread.current['namespace'])
  exons.attach TSV.open('gene_positions'), :fields => ["Chromosome Name"]

  Misc.sensiblewrite(t.name, exons.to_s)
end

file 'transcript_exons' do |t|
  exons = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_exons, [], nil, :keep_empty => true, :namespace => Thread.current['namespace'])

  Misc.sensiblewrite(t.name, exons.to_s)
end

file 'exon_phase' do |t|
  exons = BioMart.tsv($biomart_db, $biomart_ensembl_exon, $biomart_exon_phase, [], nil, :keep_empty => true, :namespace => Thread.current['namespace'])

  Misc.sensiblewrite(t.name, exons.to_s)
end


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

  Misc.sensiblewrite(t.name, tsv.to_s)
end


#{{{ Variations

$biomart_variation_id = ["SNP ID", "refsnp_id"]
$biomart_variation_position = [["Chromosome Name", "chr_name"], ["Chromosome Start", "chrom_start"], ["Variant Alleles", "allele"]]

file 'germline_variations' do |t|
  BioMart.tsv($biomart_db_germline_variation, $biomart_variation_id, $biomart_variation_position, [], nil, :keep_empty => true, :type => :list, :filename => t.name, :namespace => Thread.current['namespace'])
end

file 'somatic_variations' do |t|
  BioMart.tsv($biomart_db_somatic_variation, $biomart_variation_id, $biomart_variation_position, [], nil, :keep_empty => true, :type => :list, :filename => t.name, :namespace => Thread.current['namespace'])
end


# {{{ Other info

file 'gene_pmids' do |t|
  tsv =  Entrez.entrez2pubmed($taxs)
  text = "#: :namespace=#{Thread.current['namespace']}\n"
  text += "#Entrez Gene ID\tPMID"
  tsv.each do |gene, pmids|
    text << "\n" << gene << "\t" << pmids * "|"
  end
  Misc.sensiblewrite(t.name, text)
end

def coding_transcripts_for_exon(exon, exon_transcripts, transcript_info) 
  transcripts = begin
                  exon_transcripts[exon].first
                rescue
                  []
                end

  #transcripts.reject{|transcript| transcript_info[transcript].first.empty?}
  transcripts
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
  exon_transcripts = nil
  exon_transcripts = TSV.open('transcript_exons', :double, :key_field => "Ensembl Exon ID", :fields => ["Ensembl Transcript ID"], :merge => true)
  gene_transcripts = TSV.open('gene_transcripts', :flat)
  transcript_info  = TSV.open('transcripts', :list, :fields => ["Ensembl Protein ID"])
  transcript_exons = TSV.open('transcript_exons', :double, :fields => ["Ensembl Exon ID","Exon Rank in Transcript"])

  string = "#: :namespace=#{Thread.current['namespace']}\n"
  string += "#Ensembl Exon ID\tEnsembl Transcript ID\tOffset\n"

  exon_transcripts.unnamed = true
  gene_transcripts.unnamed = true
  transcript_info.unnamed = true
  transcript_exons.unnamed = true

  exons = TSV.open('exons')
  exons.unnamed = true
  exons.monitor = true
  exons.through do |exon, info|
    exon = exon.first if Array === exon
    gene, start, finish, strand, chr = info

    transcripts = coding_transcripts_for_exon(exon, exon_transcripts, transcript_info)

    transcript_offsets = {}
    transcripts.each do |transcript|
      offset = exon_offset_in_transcript( exon, transcript, exons, transcript_exons)
      transcript_offsets[transcript] = offset unless offset.nil?
    end

    string << exon << "\t" << transcript_offsets.keys * "|" << "\t" << transcript_offsets.values * "|" << "\n"
  end

  Misc.sensiblewrite(t.name, string)
end

file 'gene_go' do |t|
  if File.basename(FileUtils.pwd) =~ /^[a-z]{3}([0-9]{4})$/i and $1.to_i <= 2009
    goterms = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_go_2009, [], nil, :type => :double, :namespace => Thread.current['namespace'])

    goterms.each do |key, values|
      values.each do |list| list.uniq! end
    end

    goterms.add_field "GO ID" do |key, values|
      values.flatten.compact.reject{|go| go.empty?}
    end

    goterms.add_field "GO Namespace" do |key, values|
      ["biological_process"] * values["GO BP ID"].reject{|go| go.empty?}.length +
        ["cellular_component"] * values["GO CC ID"].reject{|go| go.empty?}.length +
        ["molecular_function"] * values["GO MF ID"].reject{|go| go.empty?}.length 
    end

    Misc.sensiblewrite(t.name, goterms.slice(["GO ID", "GO Namespace"]).to_s)
  else
    goterms = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_go, [], nil, :type => :double, :namespace => Thread.current['namespace'])

    Misc.sensiblewrite(t.name, goterms.to_s)
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


  gene_go.filename = t.name
  Misc.sensiblewrite(t.name, gene_go.slice("GO ID").to_s)
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


  gene_go.filename = t.name
  Misc.sensiblewrite(t.name, gene_go.slice("GO ID").to_s)
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


  gene_go.filename = t.name
  Misc.sensiblewrite(t.name, gene_go.slice("GO ID").to_s)
end



file 'gene_biotype' do |t|
  biotype = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_gene_biotype, [], nil, :type => :single, :namespace => Thread.current['namespace'])

  Misc.sensiblewrite(t.name, biotype.to_s)
end

file 'transcript_biotype' do |t|
  biotype = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_biotype, [], nil, :type => :single, :namespace => Thread.current['namespace'])

  Misc.sensiblewrite(t.name, biotype.to_s)
end

file 'transcript_name' do |t|
  biotype = BioMart.tsv($biomart_db, $biomart_ensembl_transcript, $biomart_transcript_name, [], nil, :type => :single, :namespace => Thread.current['namespace'])

  Misc.sensiblewrite(t.name, biotype.to_s)
end

file 'gene_pfam' do |t|
  pfam = BioMart.tsv($biomart_db, $biomart_ensembl_gene, $biomart_pfam, [], nil, :type => :double, :namespace => Thread.current['namespace'])

  Misc.sensiblewrite(t.name, pfam.to_s)
end

file 'chromosomes' do |t|
  goterms = BioMart.tsv($biomart_db, ['Chromosome Name', "chromosome_name"] , [] , [], nil, :type => :double, :namespace => Thread.current['namespace'])

  Misc.sensiblewrite(t.name, goterms.to_s)
end

file 'blacklist_chromosomes' => 'chromosomes' do |t|
  list = TSV.open(t.prerequisites.first).keys.select{|c| c.index('_') or c.index('.')}
  File.open(t.name, 'w') do |f| f.puts list * "\n" end
end

file 'blacklist_genes' => ['blacklist_chromosomes', 'gene_positions'] do |t|
  Open.read(t.prerequisites.first)
  genes = CMD.cmd("grep -f '#{t.prerequisites.first}' | cut -f 1", :in => Open.open(t.prerequisites.last)).read.split("\n").uniq
  Misc.sensiblewrite(t.name, genes * "\n")
end

file 'sanctioned_genes' => ['blacklist_genes', 'gene_positions'] do |t|
  genes = CMD.cmd("cut -f 1", :in => Open.open(t.prerequisites.last)).read.split("\n").uniq - Open.read(t.prerequisites.first).split("\n")
  Misc.sensiblewrite(t.name, genes * "\n")
end


rule /^chromosome_.*/ do |t|
  chr = t.name.match(/chromosome_(.*)/)[1]

  # HACK: Skip LRG chromosomes
  raise "LRG and GL chromosomes not supported: #{ chr }" if chr =~ /^(?:LRG_|GL0)/

  archive = File.basename(FileUtils.pwd) =~ /^([a-z]{3}[0-9]{4})$/i ? $1 : nil

  release = Ensembl.releases[archive]

  ftp = Net::FTP.new("ftp.ensembl.org")
  ftp.passive = true
  ftp.login
  if release.nil? or release == 'current'
    ftp.chdir("pub/current_fasta/")
  else
    ftp.chdir("pub/#{ release }/fasta/")
  end
  ftp.chdir($scientific_name.downcase.sub(" ",'_'))
  ftp.chdir('dna')
  file = ftp.nlst.select{|file| file =~ /chromosome\.#{ chr }\.fa/}.first

  raise "Fasta file for chromosome not found: '#{ chr }' - #{ archive }, #{ release }" if file.nil?

  Log.debug("Downloading chromosome sequence: #{ file } - #{release} #{t.name}")

  Misc.lock t.name + '.rake' do
    TmpFile.with_file do |tmpfile|
      ftp.getbinaryfile(file, tmpfile)
      Misc.sensiblewrite(t.name, Open.read(tmpfile, :gzip => true).sub(/^>.*\n/,'').gsub(/\s/,''))
      ftp.close
    end
  end
end

rule /^possible_ortholog_(.*)/ do |t|
  other = t.name.match(/ortholog_(.*)/)[1]
  other_key = Organism.ortholog_key(other).produce.read
  BioMart.tsv($biomart_db, $biomart_ensembl_gene, [["Ortholog Ensembl Gene ID", "inter_paralog_" + other_key]], [], nil, :keep_empty => false, :type => :double, :filename => t.name, :namespace => Thread.current['namespace'])
end

rule /^ortholog_(.*)/ do |t|
  other = t.name.match(/ortholog_(.*)/)[1]
  other_key = Organism.ortholog_key(other).produce.read
  BioMart.tsv($biomart_db, $biomart_ensembl_gene, [["Ortholog Ensembl Gene ID", other_key]], [], nil, :keep_empty => false, :type => :double, :filename => t.name, :namespace => Thread.current['namespace'])
end

rule /[a-z]{3}[0-9]{4}\/.*/i do |t|
  t.name =~ /([a-z]{3}[0-9]{4})\/(.*)/i
  archive = $1
  task    = $2
  Misc.in_dir(archive) do
    BioMart.set_archive archive
    begin
      old_namespace = Thread.current['namespace']
      Thread.current['namespace'] = Thread.current['namespace'] + "/" << archive
      Rake::Task[task].invoke
    rescue
      Log.error "Error producing archived (#{archive}) version of #{task}: #{t.name}"
      raise $!
    ensure
      Thread.current['namespace'] = old_namespace
    end
    BioMart.unset_archive 
  end
end





#{{{ Special files
require 'bio'

file 'transcript_sequence' => ["exons", "transcript_exons", "blacklist_chromosomes"] do |t|
  exon_info = TSV.open('exons', :type => :list, :fields => ["Exon Strand", "Exon Chr Start", "Exon Chr End", "Chromosome Name"], :unnamed => true)

  chr_transcript_ranges ||= {}
  transcript_strand = {}

  blacklist_chromosomes = Path.setup(File.expand_path('blacklist_chromosomes')).list
  transcript_exons = Path.setup(File.expand_path('transcript_exons'))
  TSV.traverse transcript_exons do |transcript,values|
    transcript = transcript.first if Array === transcript
    transcript_ranges = []

    exons = Misc.zip_fields(values).sort_by{|exon,rank| rank.to_i}.collect{|exon,rank| exon}

    chr = nil
    strand = nil
    exons.each do |exon|
      strand, start, eend, chr = exon_info[exon]
      start = start.to_i
      eend = eend.to_i
      transcript_ranges << [start, eend]
    end

    transcript_strand[transcript] = strand

    chr_transcript_ranges[chr] ||= {}
    chr_transcript_ranges[chr][transcript] ||= transcript_ranges
  end

  transcript_sequence = {}
  chr_transcript_ranges.each do |chr, transcript_ranges|
    begin
      raise "LRG, GL, HG, NT, KI, and HSCHR chromosomes not supported: #{chr}" if blacklist_chromosomes.include? chr
      p = File.expand_path("./chromosome_#{chr}")
      Organism.root.annotate p
      p.sub!(%r{.*/organisms/},'share/organisms/')
      chr_str = p.produce.read
    rescue Exception
      Log.warn("Chr #{ chr } failed (#{transcript_ranges.length} transcripts not covered): #{$!.message}")
      raise $! unless $!.message =~ /not supported/
      next
    end

    transcript_ranges.each do |transcript, ranges|
      strand = transcript_strand[transcript]
      ranges = ranges.reverse if strand == "-1"

      sequence = ranges.inject(""){|acc, range|
        start, eend = range
        raise "Chromosome #{ chr } is too short (#{eend - chr_str.length } bases) for transcript #{ transcript } ([#{ start }, #{ eend }])." if chr_str.length < eend
        acc << chr_str[start-1..eend-1]
      }

      sequence = Bio::Sequence::NA.new(sequence).complement.upcase if strand == "-1"
      transcript_sequence[transcript] = sequence
    end
  end
  TSV.setup(transcript_sequence, :key_field => "Ensembl Transcript ID", :fields => ["Sequence"], :type => :single, :unnamed => true)

  Misc.sensiblewrite(t.name, transcript_sequence.to_s)
end

file 'transcript_5utr' => ["exons", "transcript_exons", "transcripts"] do |t|
  path = File.expand_path(t.name)
  dirname = File.dirname(path)

  organism = File.basename(dirname)
  if organism =~ /^[a-z]{3}20[0-9]{2}/
    archive = organism
    organism = File.basename(File.dirname(dirname))
    organism = File.join(organism, archive)
  end

  translation        = Ensembl::FTP.ensembl_tsv(organism, 'translation', 'transcript_id', %w(seq_start start_exon_id seq_end end_exon_id), :type => :list, :unmamed => true)

  if Ensembl::FTP.has_table?(organism, 'exon_stable_id')
    exon2ensembl       = Ensembl::FTP.ensembl_tsv(organism, 'exon_stable_id', 'exon_id', ['stable_id'], :type => :single, :unnamed => true) 
  else
    exon2ensembl       = Ensembl::FTP.ensembl_tsv(organism, 'exon', 'exon_id', ['stable_id'], :type => :single, :unnamed => true) 
  end

  if Ensembl::FTP.has_table?(organism, 'exon_stable_id')
    transcript2ensembl = Ensembl::FTP.ensembl_tsv(organism, 'transcript_stable_id', 'transcript_id', ['stable_id'], :type => :single, :unnamed => true) 
  else
    transcript2ensembl = Ensembl::FTP.ensembl_tsv(organism, 'transcript', 'transcript_id', ['stable_id'], :type => :single, :unnamed => true) 
  end

  transcript_protein = TSV.open("./transcripts", :key_field => "Ensembl Transcript ID", :fields => ["Ensembl Protein ID"], :type => :single,  :unmamed => true)
  transcript_exons   = TSV.open("./transcript_exons", :unmamed => true)
  exon_ranges        = TSV.open("./exons",:fields => ["Exon Chr Start", "Exon Chr End"], :cast => :to_i, :unmamed => true)

  transcript_utr5 = TSV.setup({}, :key_field => "Ensembl Transcript ID", :fields => ["5' UTR Length"], :cast => :to_i, :type => :single)
  transcript_utr3 = TSV.setup({}, :key_field => "Ensembl Transcript ID", :fields => ["3' UTR Length"], :cast => :to_i, :type => :single)

  translation.through do |transcript_id, values|
    start, start_exon, eend, eend_exon = values

    transcript = transcript2ensembl[transcript_id]
    protein    = transcript_protein[transcript]

    next if transcript =~ /^LRG/

    start_exon = exon2ensembl[start_exon]
    eend_exon = exon2ensembl[eend_exon]

    raise "Transcript #{ transcript } missing exons" if transcript_exons[transcript].nil?

    exon_and_rank = Hash[*Misc.zip_fields(transcript_exons[transcript]).flatten]

    start_exon_rank = exon_and_rank[start_exon].to_i
    skipped_exons = exon_and_rank.select{|exon,rank| rank.to_i < start_exon_rank}.collect{|exon,rank| exon }
    skipped_exon_bases = skipped_exons.inject(0){|acc,exon| exon_start, exon_eend = exon_ranges[exon]; acc += exon_eend - exon_start + 1}

    utr5 = skipped_exon_bases + start.to_i - 1
    transcript_utr5[transcript] = utr5

    eend_exon_rank = exon_and_rank[eend_exon].to_i
    extra_exons = exon_and_rank.select{|exon,rank| rank.to_i >= eend_exon_rank}.collect{|exon,rank| exon }
    extra_exon_bases = extra_exons.inject(0){|acc,exon| exon_start, exon_eend = exon_ranges[exon]; acc += exon_eend - exon_start + 1}

    utr3 = extra_exon_bases - eend.to_i
    transcript_utr3[transcript] = utr3
  end

  Misc.lock t.name + '.rake' do
    Misc.sensiblewrite(t.name, transcript_utr5.to_s)
    Misc.sensiblewrite(t.name.sub('transcript_5utr', 'transcript_3utr'), transcript_utr3.to_s)
  end
end

file 'transcript_3utr' => ["transcript_5utr"] do |t|
end

file 'protein_sequence' => ["transcripts", "transcript_5utr", "transcript_3utr", "transcript_phase", "transcript_sequence"] do |t|
  transcript_5utr     = TSV.open(File.expand_path('./transcript_5utr'), :unnamed => true)
  transcript_3utr     = TSV.open(File.expand_path('./transcript_3utr'), :unnamed => true)
  transcript_phase     = TSV.open(File.expand_path('./transcript_phase'), :unnamed => true)
  transcript_sequence = TSV.open(File.expand_path('./transcript_sequence'), :unnamed => true)
  transcript_protein  = TSV.open(File.expand_path('./transcripts'), :fields => ["Ensembl Protein ID"], :type => :single, :unnamed => true)


  protein_sequence = TSV.setup({}, :key_field => "Ensembl Protein ID", :fields => ["Sequence"], :type => :single)
  transcript_sequence.through do |transcript, sequence|
    protein = transcript_protein[transcript]
    next if protein.nil? or protein.empty?

    utr5 = transcript_5utr[transcript]
    utr3 = transcript_3utr[transcript]
    phase = transcript_phase[transcript] || 0

    if phase < 0
      if utr5.nil? || utr5 == 0 || utr5 == "0"
        utr5 = 0
      end
      phase = 0
    end

    psequence = Bio::Sequence::NA.new(("N" * phase) << sequence[utr5..sequence.length-utr3-1]).translate
    protein_sequence[protein]=psequence
  end

  Misc.sensiblewrite(t.name, protein_sequence.to_s)
end

file 'ensembl2uniprot' => ["protein_sequence", "protein_identifiers"] do |t|
  ensp2unis  = TSV.open(File.expand_path('./protein_identifiers'), :key_field => "Ensembl Protein ID", :fields => ["UniProt/SwissProt Accession"], :type => :flat, :merge => true, :unnamed => true)
  dumper = TSV::Dumper.new :key_field => "Ensembl Protein ID", :fields => ["UniProt/SwissProt Accession"], :namespace => Thread.current['namespace'], :type => :single
  dumper.init
  require 'rbbt/sources/uniprot'
  TSV.traverse File.expand_path('./protein_sequence'), :into => dumper, :cpus => 20, :bar => true do |ensp,ensp_seq|
    ensp = ensp.first if Array === ensp
    unis = ensp2unis[ensp]
    next if unis.nil? or unis.empty?
    uni_seqs = UniProt.get_uniprot_sequence(unis)
    best_uni = unis.zip(uni_seqs).sort_by do |uni,uni_seq|
      (ensp_seq.length - uni_seq.length).abs
    end.first.first
    [ensp, best_uni]
  end
  Misc.sensiblewrite(t.name, dumper.stream)
end

file 'uniprot2ensembl' => ["protein_sequence", "protein_identifiers"] do |t|
  uni2ensps  = TSV.open(File.expand_path('./protein_identifiers'), :fields => ["Ensembl Protein ID"], :key_field => "UniProt/SwissProt Accession", :type => :flat, :merge => true, :unnamed => true)
  ensp2seq  = TSV.open(File.expand_path('./protein_sequence'), :unnamed => true)
  dumper = TSV::Dumper.new :fields => ["Ensembl Protein ID"], :key_field => "UniProt/SwissProt Accession", :namespace => Thread.current['namespace'], :type => :single
  dumper.init
  require 'rbbt/sources/uniprot'
  all_uni  = TSV.open(File.expand_path('./protein_identifiers'), :key_field => "UniProt/SwissProt Accession", :fields => [], :type => :double, :merge => true, :unnamed => true).keys.compact.reject{|u| u.empty?}
  TSV.traverse all_uni, :into => dumper, :cpus => 1, :bar => true do |uni|
    uni = uni.first if Array === uni
    uni_seq = UniProt.get_uniprot_sequence(uni)
    ensps = uni2ensps[uni]
    next if ensps.nil? or ensps.empty?
    best_ensp = ensps.sort_by do |ensp|
      ensp_seq = ensp2seq[ensp]
      if ensp_seq
        (ensp_seq.length - uni_seq.length).abs
      else
        uni_seq.length
      end
    end.first
    [uni, best_ensp]
  end
  Misc.sensiblewrite(t.name, dumper.stream)
end

file 'gene_set' do |t|
  path = File.expand_path(t.name)
  dirname = File.dirname(path)

  organism = File.basename(dirname)
  if organism =~ /^[a-z]{3}20[0-9]{2}/
    archive = organism
    organism = File.basename(File.dirname(dirname))
    organism = File.join(organism, archive)
  end

  release = Ensembl.org2release(organism)
  num = release.split("-").last
  build_code = Organism.GRC_build(organism)
  scientific_name = $scientific_name
  url = "ftp://ftp.ensembl.org/pub/release-#{num}/gtf/#{scientific_name.downcase.sub(" ", '_')}/#{scientific_name.sub(" ", '_')}.#{build_code}.#{num}.gtf.gz"
  CMD.cmd("wget '#{url}' -O #{t.name}.gz")
  nil
end

file 'cdna_fasta' do |t|
  path = File.expand_path(t.name)
  dirname = File.dirname(path)

  organism = File.basename(dirname)
  if organism =~ /^[a-z]{3}20[0-9]{2}/
    archive = organism
    organism = File.basename(File.dirname(dirname))
    organism = File.join(organism, archive)
  end

  release = Ensembl.org2release(organism)
  num = release.split("-").last
  build_code = Organism.GRC_build(organism)
  scientific_name = Organism.scientific_name(organism)
  url = "ftp://ftp.ensembl.org/pub/release-#{num}/fasta/#{scientific_name.downcase.sub(" ", '_')}/cdna/#{scientific_name.sub(" ", '_')}.#{build_code}.cdna.all.fa.gz"
  CMD.cmd("wget '#{url}' -O #{t.name}.gz")
  nil
end
