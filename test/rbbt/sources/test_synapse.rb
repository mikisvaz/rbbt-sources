require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt-util'
require 'rbbt/sources/synapse'

class TestSynapse < Test::Unit::TestCase
  def sandbox_syn
    "syn4231273"
  end

  def sftp_sandbox_syn
    "syn4231379"
  end


  def _test_upload_file
    TmpFile.with_file("test", true, :extension => 'tsv') do |filename|
      ppp Synapse.upload_file(filename, sandbox_syn)
    end
  end

  def _test_upload_files
    TmpFile.with_file do |directory|
      FileUtils.mkdir_p directory unless File.exists? directory
      filename1 = File.join(directory, 'test1.txt')
      Open.write(filename1, 'test1')
      filename2 = File.join(directory, 'test2.txt')
      Open.write(filename2, 'test2')

      files = {filename1 => {}, filename2 => {}}

      iii Synapse.upload_files(files, sandbox_syn)
    end
  end

  def _test_create_directory
    TmpFile.with_file() do |directory|
      ppp Synapse.create_directory(File.basename(directory), sandbox_syn)
    end
  end

  def _test_create_directories
    ppp Synapse.create_directories([rand(100).to_s, rand(100).to_s], sandbox_syn)
  end

  def _test_upload_dir
    TmpFile.with_file do |directory|
      FileUtils.mkdir_p directory unless File.exists? directory
      subdir1 = File.join(directory, 'subdir1')
      FileUtils.mkdir_p subdir1 unless File.exists? subdir1
      subdir2 = File.join(directory, 'subdir2')
      FileUtils.mkdir_p subdir1 unless File.exists? subdir2

      subdir3 = File.join(subdir2, 'subdir3')

      Open.write(File.join(subdir1, 'file1.txt'), 'test1')
      Open.write(File.join(subdir2, 'file2.txt'), 'test2')
      Open.write(File.join(subdir3, 'file3.txt'), 'test3')

      ppp `ls -R #{directory}`

      annotation_proc = Proc.new do |path|
        case path
        when /file1/
          {:content_type => "text/markdown"}
        when /file2/
          {:name => "Test file 2"}
        when /file3/
          nil
        else
          {}
        end
      end
      newsyn = Synapse.create_directory('test_upload_dir.' + rand(100).to_s, sandbox_syn)
      ppp Synapse.upload_dir(directory, newsyn, annotation_proc)
    end
  end
end

