require 'rbbt-util'

module COSTART

  Rbbt.share.databases.COSTART.COSTART.define_as_proc do 
      terms = ["#COSTART Terms"]
      Open.open('http://hedwig.mgh.harvard.edu/biostatistics/files/costart.html').lines.each do |line|
        puts line
        next unless line =~ /^'(.*)',/
        terms << $1
      end
      
      terms * "\n"
  end
end
