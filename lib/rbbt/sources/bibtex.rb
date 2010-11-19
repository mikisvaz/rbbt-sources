class BibTexFile

  class Entry

    FIELDS = %w(pmid title author journal pages number volume year abstract)
    
    FIELDS.each do |field|
      define_method(field, proc{@info[field]})
    end

    attr_reader :info, :fields, :name, :type
    def initialize(name, type, info)
      @name = name
      @type = type
      @info = info
      @fields = info.keys
    end

    def method_missing(name, *args)
      if name.to_s =~ /(.*)=$/
        if (FIELDS + @fields).include?($1.to_s)
          return @info[$1.to_s] = args[0].chomp
        else
          raise "No field named '#{ $1 }'"
        end
      else
        if @fields.include?(name.to_s)
          return @info[name.to_s]
        else
          raise "No field named '#{ name }'"
        end
      end
    end

    def to_s
      str = "@#{type}{#{name},\n"

      FIELDS.each do |field|
        next if field.nil?
        str += "    #{field} = {#{@info[field]}},\n"
      end

      (fields - FIELDS).sort.each do |field|
        str += "    #{field} = {#{@info[field]}},\n"
      end

      str += "}"

      str
    end
  end

  def self.clean_string(string)
    string.gsub(/[{}]/,'')
  end

  def self.parse_bibtex(bibtex)
    bibtex.scan(/@\w+\{.*?^\}\s*/m)
  end

  def self.parse_entry(entry)
    info = {}

    type, name = entry.match(/@([^\s]+)\{([^\s]+)\s*,/).values_at(1,2)
    
    entry.scan(/\s*(.*?)\s*=\s*\{?\s*(.*?)\s*\}?\s*,?\s*$/).each do |pair|
      info[pair.first.chomp] = pair.last.chomp
    end

    [ type.chomp, name.chomp, info]
  end

  def self.load_file(file)
    entries = {}

    case
    when File.exists?(file)
      self.parse_bibtex File.open(file).read 
    when IO === file
      self.parse_bibtex file.read
    when String === file
      self.parse_bibtex file
    else
      raise "Input format not recognized"
    end.each do |entry|
      type, name, info = self.parse_entry entry
      entries[name] = Entry.new name, type, info
    end

    entries
  end

  def initialize(file)
    @entries = BibTexFile.load_file(file)
  end

  def save(file)
    text = entries.collect{|e| entry e }.sort{|a,b| 
      if a.year.to_i != b.year.to_i
        a.year.to_i <=> b.year.to_i
      else
        a.name <=> b.name
      end
    }.reverse.collect do |entry|
      entry.to_s
    end * "\n"

    File.open(file, 'w') do |fout| fout.puts text end
  end

  def add(bibtex)
    type, name, info = BibTexFile.parse_entry bibtex
    @entries[name] = BibTexFile::Entry.new name, type, info
  end

  def entries
    @entries.keys
  end

  def entry(bibentry)
    @entries[bibentry]
  end
end

if __FILE__ == $0

  b = BibTexFile.new('/home/miki/git/DrugReview/drug.bib')
  puts b.entry("yao2009novel").to_s
  b.save('foo.bib')
end
