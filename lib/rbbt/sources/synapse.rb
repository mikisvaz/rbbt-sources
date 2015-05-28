module Synapse

  PYTHON_LOGIN_TEMPLATE =<<-EOF
import synapseclient
syn = synapseclient.login()

  EOF

  PYTHON_FILE_TEMPLATE =<<-EOF
f = synapseclient.File('[FILE]', parentId='[PARENTID]', name='[NAME]', contentType='[CONTENT-TYPE]')
[ANNOTATIONS]

  EOF
  
  PYTHON_SEND_TEMPLATE =<<-EOF
f = syn.store(f, used= [USED], executed = [EXECUTED])
print("syn: " + f.id)

  EOF

  PYTHON_DIR_TEMPLATE =<<-EOF
f = synapseclient.Folder('[NAME]', parentId='[PARENTID]')
f = syn.store(f)
print("syn: " + f.id)

  EOF

  def self.python_login
    PYTHON_LOGIN_TEMPLATE.dup
  end

  def self.python_create_dir(name, parentid)
    name = File.basename(name)
    template = PYTHON_DIR_TEMPLATE.dup

    template.sub!('[PARENTID]', parentid)
    template.sub!('[NAME]', name)

    template
  end

  def self.python_upload_template(used = nil, executed = nil)
    template = PYTHON_SEND_TEMPLATE.dup
    if used
      used_str = "#{used.inspect}"
    else
      used_str = "[]"
    end

    if executed
      executed_str = "'#{executed}'"
    else
      executed_str = "''"
    end

    template.sub!('[USED]', used_str)
    template.sub!('[EXECUTED]', executed_str)

    template
  end

  def self.python_file_template(file, parentid, name = nil, content_type = nil, annotations = {})
    template = PYTHON_FILE_TEMPLATE.dup

    annotations = {} if annotations.nil?

    name = annotations.delete :name if name.nil?
    name = File.basename(file) if name.nil?

    content_type = annotations.delete :content_type if content_type.nil?
    content_type = begin
                     MimeMagic.by_path(file) 
                   rescue
                     'text/plain'
                   end if content_type.nil?

    template.sub!('[FILE]', file)
    template.sub!('[PARENTID]', parentid)
    template.sub!('[NAME]', name)
    template.sub!('[CONTENT-TYPE]', content_type)

    if annotations
      annotation_str = annotations.collect{|k,v| "f.#{k} = '#{v}'"} * "\n"
      template.sub!('[ANNOTATIONS]', annotation_str)
    else
      template.sub!('[ANNOTATIONS]', '')
    end

    template
  end

  def self.upload_file(file, syn, name=nil, content_type=nil, annotations = {})
    template = python_login + python_file_template(file, syn, name, content_type, annotations) + python_upload_template
    syn = Misc.insist do
      Log.warn "Uploading file: #{file}"
      TmpFile.with_file(template) do |ftemplate|
        `python '#{ ftemplate }'`.match(/syn: (syn\d+)/)[1]
      end
    end
    syn
  end

  def self.upload_files(files, syn)
    template = python_login 
    order = []
    files.each do |file,info|
      order << file
      name, content_type, annotations = info.values_at :name, :content_type, :annotations
      template << python_file_template(file, syn, name, content_type, annotations) + python_upload_template
    end

    syns = Misc.insist do
      Log.warn "Uploading files: #{Misc.fingerprint files}"
      TmpFile.with_file(template) do |ftemplate|
        res = `python '#{ ftemplate }'`
        res.scan(/syn: syn\d+/).collect{|m| m.match(/(syn\d+)/)[0]}
      end
    end
    Hash[*order.zip(syns).flatten]
  end

  def self.create_directory(dir, syn)
    template = python_login + python_create_dir(dir, syn)
    syn = Misc.insist do
      Log.warn "Creating directory: #{dir}"
      TmpFile.with_file(template) do |ftemplate|
        `python '#{ ftemplate }'`.match(/syn: (syn\d+)/)[1]
      end
    end
    syn
  end

  def self.create_directories(dirs, syn)
    template = python_login 
    order = []
    dirs.each do |dir|
      order << dir
      template <<  python_create_dir(dir, syn)
    end
    syns = Misc.insist do
      TmpFile.with_file(template) do |ftemplate|
        Log.warn "Creating directories: #{Misc.fingerprint dirs}"
        res = `python '#{ ftemplate }'`
        res.scan(/syn: syn\d+/).collect{|m| m.match(/(syn\d+)/)[0]}
      end
    end
    Hash[*order.zip(syns).flatten]
  end

  def self.directory_structure(directory)
    structure = {}
    Dir.glob(File.join(directory, '*')).each do |path|
      if File.directory? path
        structure[path] = directory_structure(path)
      end
    end
    structure
  end

  def self.upload_dir(directory, syn, file_annotations = {})
    Log.warn "Uploading #{ Log.color :blue, directory }"
    files = Dir.glob(File.join(directory, '*')).reject{|f| File.directory? f}
    file_info = {}
    files.each{|file| file_info[file] = file_annotations[file] || {} } if Hash === file_annotations
    files.each{|file| file_info[file] = file_annotations.call(file) || {} } if Proc === file_annotations
    files.each{|file| file_info[file] = {} } if file_annotations.nil?

    Log.warn "Uploading #{ Log.color :blue, directory } files: #{Misc.fingerprint files}"
    upload_files(file_info, syn)

    structure = directory_structure(directory)
    directories = structure.keys
    diretories_syns = create_directories(directories, syn)
    Log.warn "Traversing #{ directory } subdirectories"
    diretories_syns.each do |subdirectory,subsyn|
      upload_dir(subdirectory, subsyn, file_annotations)
    end
  end
end

<<-'EOF'

metadata = YAML.load(Open.open(metadata_file))
IndiferentHash.setup metadata


Log.info "Creating file #{file} in #{metadata[:parentid]}"
syn = Misc.insist do
  TmpFile.with_file(template) do |ftemplate|
    `python '#{ ftemplate }'`.match(/syn: (syn\d+)/)[1]
  end
end

Log.info "Created file #{file} in #{metadata[:parentid]}: #{ syn }"

puts syn

import synapseclient
syn = synapseclient.login()

[CONTENT-TYPE]

f = synapseclient.File('[FILE]', parentId='[PARENTID]', name='[NAME]', contentType=contentType)

#Lets set some annotations on the file
#f.fileType = 'vcf'
#f.pipeline = 'Sanger'
#f.variant_type = 'indel'
[ANNOTATIONS]

#used = ['https://cghub.ucsc.edu/cghub/data/analysis/download/ba7ba416-a215-4bcf-b1b4-d6deaae0a645', 'https://cghub.ucsc.edu/cghub/data/analysis/download/7f733401-be7f-4fbe-b966-529f5574cbab']
#executed = 'https://github.com/ICGC-TCGA-PanCancer/SeqWare-CGP-SomaticCore'
[PROVENANCE]

#Lets store the file to Synapse and set the provenance
f = syn.store(f, used= used, executed = executed)
print("syn: " + f.id)
EOF
