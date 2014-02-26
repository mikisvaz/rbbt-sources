$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../../../lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rbbt/tsv'
require 'rbbt/util/open'
require 'rbbt/util/log'

SOURCE_DIR = 'source'
def define_source_tasks(sources)
  sources.each do |name, url|
    file File.join(SOURCE_DIR, name) do |t|
      FileUtils.mkdir SOURCE_DIR unless File.exists? SOURCE_DIR
      Log.log "Retrieving file '#{name}' into '#{t.name}': '#{url}'", Log::LOW
      Open.write(t.name, Open.open(url, :cache => false, :wget_options => {"--no-check-certificate" => true, "--quiet" => false, :pipe => true}))
    end
  end
end

$__headers = nil
def headers(values)
  $__headers = values
end

$__data = nil
def data(&block)
  $__data = block
end

$__tsv_tasks = []
def tsv_tasks
  $__tsv_tasks 
end

$__files = []
def add_to_defaults(list)
  $__files = list
end

def process_tsv(file, source, options = {}, &block)

  $__tsv_tasks << file

  file file => File.join(SOURCE_DIR, source) do |t|
    block.call

    d = TSV.open(t.prerequisites.first, options)

    if d.fields != nil
      data_fields = d.fields.dup.unshift d.key_field
      if $__headers.nil?
        $__headers = data_fields
      end
    end

    if d.fields
      headers = d.fields.dup.unshift d.key_field
    else
      headers = nil
    end

    File.open(t.name.to_s, 'w') do |f|
      f.puts "#" + $__headers * "\t" if $__headers != nil
      d.each do |key, values|
        if $__data.nil?
          line = values.unshift key
        else
          line = $__data.call key, values
        end

        if Array === line
          key   = line.shift
          fields = line.collect{|elem| Array === elem ? elem * "|" : elem }
          fields.unshift key
          f.puts fields * "\t" 
        else
          f.puts line
        end
      end
    end
  end
end

task :default do |t|
  ($__tsv_tasks + $__files).each do |file| Rake::Task[file].invoke end
end

task :all => :default 

task :clean do
  ($__tsv_tasks + $__files).each do |file| FileUtils.rm file.to_s if File.exists?(file.to_s) end
end
