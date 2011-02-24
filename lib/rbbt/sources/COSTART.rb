require 'rbbt-util'

module COSTART

  Rbbt.claim "COSTART", 
    Proc.new{
      terms = ["#COSTART Terms"]
      Open.open('http://hedwig.mgh.harvard.edu/biostatistics/files/costart.html').lines.each do |line|
        puts line
        next unless line =~ /^'(.*)',/
        terms << $1
      end
      
      terms * "\n"
    }, 'COSTART'
end
