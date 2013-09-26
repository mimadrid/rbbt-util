require 'lockfile'
require 'rbbt/util/chain_methods'
require 'rbbt/resource/path'
require 'rbbt/annotations'
require 'net/smtp'
require 'digest/md5'

class Hash
  def chunked_values_at(keys, max = 5000)
    Misc.ordered_divide(keys, max).inject([]) do |acc,c|
      new = self.values_at(*c)
      new.annotate acc if new.respond_to? :annotate and acc.empty?
      acc.concat(new)
    end
  end
end

module Misc
  class FieldNotFoundError < StandardError;end

  def self.correct_icgc_mutation(pos, ref, mut_str)
    mut = mut_str
    mut = '-' * (mut_str.length - 1) if mut =~/^-[ACGT]/
    mut = "+" << mut if ref == '-'
    [pos, [mut]]
  end

  def self.correct_vcf_mutation(pos, ref, mut_str)
    muts = mut_str.nil? ? [] : mut_str.split(',')

    while ref.length >= 1 and muts.reject{|m| m[0] == ref[0]}.empty?
      ref = ref[1..-1]
      pos = pos + 1
      muts = muts.collect{|m| m[1..-1]}
    end

    muts = muts.collect do |m|
      case
      when ref.empty?
        "+" << m
      when (m.length < ref.length and (m.empty? or ref.index(m)))
        "-" * (ref.length - m.length)
      when (ref.length == 1 and m.length == 1)
        m
      else
        Log.debug "Cannot understand: #{[ref, m]} (#{ muts })"
        '-' * ref.length + m
      end
    end

    [pos, muts]
  end

  def self.pid_exists?(pid)
    return false if pid.nil?
    begin
      Process.getpgid(pid.to_i)
      true
    rescue Errno::ESRCH
      false
    end
  end

  COLOR_LIST = %w(#BC80BD #CCEBC5 #FFED6F #8DD3C7 #FFFFB3 #BEBADA #FB8072 #80B1D3 #FDB462 #B3DE69 #FCCDE5 #D9D9D9)

  def self.colors_for(list)
    unused = COLOR_LIST.dup

    used = {}
    colors = list.collect do |elem|
      if used.include? elem
        used[elem]
      else
        color = unused.shift
        used[elem]=color
        color
      end
    end

    [colors, used]
  end

  def self.collapse_ranges(ranges)
    processed = []
    last = nil
    ranges.sort_by{|range| range.begin }.each do |range|
      if last.nil? or range.begin > last
        processed << range
        last = range.end
      else
        new_processed = []
        processed.each do |processed_range|
          if processed_range.end < range.begin
            new_processed << processed_range
          else
            eend = [range.end, processed_range.end].max
            new_processed << (processed_range.begin..eend)
            break
          end
        end
        processed = new_processed
        last = range.end if range.end > last
      end
    end

    processed
  end

  def self.total_length(ranges)
    Misc.collapse_ranges(ranges).inject(0) do |total,range| total += range.end - range.begin + 1 end
  end


  def self.random_sample_in_range(total, size)
    p = Set.new

    if size > total / 10
      template = (0..total - 1).to_a
      size.times do |i|
        pos = (rand * (total - i)).floor
        if pos == template.length - 1
          v = template.pop
        else
          v, n = template[pos], template[-1]
          template.pop
          template[pos] = n 
        end
        p << v
      end
    else
      size.times do 
        pos = nil
        while pos.nil? 
          pos = (rand * total).floor
          if p.include? pos
            pos = nil
          end
        end
        p << pos
      end
    end
    p
  end

  def self.sample(ary, size, replacement = false)
    if ary.respond_to? :sample
      ary.sample size
    else
      total = ary.length
      p = random_sample_in_range(total, size)
      ary.values_at *p
    end
  end

  Log2Multiplier = 1.0 / Math.log(2.0)
  def self.log2(x)
    Math.log(x) * Log2Multiplier
  end

  def self.prepare_entity(entity, field, options = {})
    return entity unless defined? Entity
    return entity unless String === entity or Array === entity
    options ||= {}

    dup_array = options.delete :dup_array

    if Annotated === field or Entity.respond_to?(:formats) and Entity.formats.include? field
      params = options.dup

      params[:format] ||= params.delete "format"
      params.merge!(:format => field) unless params.include?(:format) and not ((f = params[:format]).nil? or (String === f and f.empty?))

      mod = Entity === field ? field : Entity.formats[field]
      entity = mod.setup(
        ((entity.frozen? and not entity.nil?) ? entity.dup : ((Array === entity and dup_array) ? entity.collect{|e| e.nil? ? e : e.dup} : entity) ),
        params
      ) 
    end

    entity
  end
 
  ARRAY_MAX_LENGTH = 1000
  STRING_MAX_LENGTH = ARRAY_MAX_LENGTH * 10

  def self.sanitize_filename(filename, length = 254)
    if filename.length > length
      if filename =~ /(\..{2,9})$/
        extension = $1
      else
        extension = ''
      end

      post_fix = "--#{filename.length}@#{length}_#{Misc.digest(filename)[0..4]}" + extension

      filename = filename[0..(length - post_fix.length - 1)] << post_fix
    else
      filename
    end
    filename
  end

  def self.remove_long_items(obj)
    case
    when TSV === obj
      remove_long_items((obj.all_fields || []) + obj.keys.sort)
    when (Array === obj and obj.length > ARRAY_MAX_LENGTH)
      remove_long_items(obj[0..ARRAY_MAX_LENGTH-2] << "TRUNCATED at #{ ARRAY_MAX_LENGTH } (#{obj.length})")
    when (Hash === obj and obj.length > ARRAY_MAX_LENGTH)
      remove_long_items(obj.collect.compact[0..ARRAY_MAX_LENGTH-2] << ["TRUNCATED", "at #{ ARRAY_MAX_LENGTH } (#{obj.length})"])
    when (String === obj and obj.length > STRING_MAX_LENGTH)
      obj[0..STRING_MAX_LENGTH-1] << " TRUNCATED at #{STRING_MAX_LENGTH} (#{obj.length})"
    when Hash === obj
      new = {}
      obj.each do |k,v|
        new[k] = remove_long_items(v)
      end
      new
    when Array === obj
      obj.collect do |e| remove_long_items(e) end
    else
      obj
    end
  end

  def self.ensembl_server(organism)
    date = organism.split("/")[1]
    if date.nil?
      "www.ensembl.org"
    else
      "#{ date }.archive.ensembl.org"
    end
  end

  def self.filename?(string)
    String === string and string.length > 0 and string.length < 250 and File.exists?(string)
  end

  def self.max(list)
    max = nil
    list.each do |v|
      next if v.nil?
      max = v if max.nil? or v > max
    end
    max
  end

  def self.google_venn(list1, list2, list3, name1 = nil, name2 = nil, name3 = nil, total = nil)
    name1 ||= "list 1"
    name2 ||= "list 2"
    name3 ||= "list 3"

    sizes = [list1, list2, list3, list1 & list2, list1 & list3, list2 & list3, list1 & list2 & list3].collect{|l| l.length}

    total = total.length if Array === total

    label = "#{name1}: #{sizes[0]} (#{name2}: #{sizes[3]}, #{name3}: #{sizes[4]})"
    label << "|#{name2}: #{sizes[1]} (#{name1}: #{sizes[3]}, #{name3}: #{sizes[5]})"
      label << "|#{name3}: #{sizes[2]} (#{name1}: #{sizes[4]}, #{name2}: #{sizes[5]})"
      if total
        label << "| INTERSECTION: #{sizes[6]} TOTAL: #{total}"
      else
        label << "| INTERSECTION: #{sizes[6]}"
      end

    max = total || sizes.max
    sizes = sizes.collect{|v| (v.to_f/max * 100).to_i.to_f / 100}
    url = "https://chart.googleapis.com/chart?cht=v&chs=500x300&chd=t:#{sizes * ","}&chco=FF6342,ADDE63,63C6DE,FFFFFF&chdl=#{label}"
  end

  def self.sum(list)
    list.compact.inject(0.0){|acc,e| acc += e}
  end

  def self.mean(list)
    sum(list) / list.compact.length
  end

  def self.sd(list)
    return nil if list.length < 3
    mean = mean(list)
    Math.sqrt(list.compact.inject(0.0){|acc,e| d = e - mean; acc += d * d}) / (list.compact.length - 1)
  end

  def self.consolidate(list)
    list.inject(nil){|acc,e|
      if acc.nil?
        acc = e
      else
        acc.concat e
        acc
      end
    }
  end

  def self.positional2hash(keys, *values)
    if Hash === values.last
      extra = values.pop
      inputs = Misc.zip2hash(keys, values)
      inputs.delete_if{|k,v| v.nil? or (String === v and v.empty?)}
      inputs = Misc.add_defaults inputs, extra
      inputs.delete_if{|k,v| not keys.include?(k) and not (Symbol === k ? keys.include?(k.to_s) : keys.include?(k.to_sym))}
      inputs
    else
      Misc.zip2hash(keys, values)
    end
  end

  def self.send_email(from, to, subject, message, options = {})
    IndiferentHash.setup(options)
    options = Misc.add_defaults options, :from_alias => nil, :to_alias => nil, :server => 'localhost', :port => 25, :user => nil, :pass => nil, :auth => :login
    IndiferentHash.setup(options)

    server, port, user, pass, from_alias, to_alias, auth = Misc.process_options options, :server, :port, :user, :pass, :from_alias, :to_alias, :auth

    msg = <<-END_OF_MESSAGE
From: #{from_alias} <#{from}>
To: #{to_alias} <#{to}>
Subject: #{subject}

#{message}
END_OF_MESSAGE

Net::SMTP.start(server, port, server, user, pass, auth) do |smtp|
  smtp.send_message msg, from, to
end
  end

  def self.counts(array)
    counts = {}
    array.each do |e|
      counts[e] ||= 0
      counts[e] += 1
    end

    counts
  end

  def self.proportions(array)
    total = array.length

    proportions = Hash.new 0

    array.each do |e|
      proportions[e] += 1.0 / total
    end

    class << proportions; self;end.class_eval do
      def to_s
        sort{|a,b| a[1] == b[1] ? a[0] <=> b[0] : a[1] <=> b[1]}.collect{|k,c| "%3d\t%s" % [c, k]} * "\n"
      end
    end

    proportions
  end

  IUPAC2BASE = {
    "A" => ["A"],
    "C" => ["C"],
    "G" => ["G"],
    "T" => ["T"],
    "U" => ["U"],
    "R" => "A or G".split(" or "),
    "Y" => "C or T".split(" or "),
    "S" => "G or C".split(" or "),
    "W" => "A or T".split(" or "),
    "K" => "G or T".split(" or "),
    "M" => "A or C".split(" or "),
    "B" => "C or G or T".split(" or "),
    "D" => "A or G or T".split(" or "),
    "H" => "A or C or T".split(" or "),
    "V" => "A or C or G".split(" or "),
    "N" => %w(A C T G),
  }

  BASE2COMPLEMENT = {
    "A" => "T",
    "C" => "G",
    "G" => "C",
    "T" => "A",
    "U" => "A",
  }

  THREE_TO_ONE_AA_CODE = {
    "ala" =>   "A",
    "arg" =>   "R",
    "asn" =>   "N",
    "asp" =>   "D",
    "cys" =>   "C",
    "glu" =>   "E",
    "gln" =>   "Q",
    "gly" =>   "G",
    "his" =>   "H",
    "ile" =>   "I",
    "leu" =>   "L",
    "lys" =>   "K",
    "met" =>   "M",
    "phe" =>   "F",
    "pro" =>   "P",
    "ser" =>   "S",
    "thr" =>   "T",
    "trp" =>   "W",
    "tyr" =>   "Y",
    "val" =>   "V"
  }

  def self.fast_align(reference, sequence)
    require 'narray'
    init_gap = -1
    gap = -2
    diff = -2
    same = 2

    cols = sequence.length + 1
    rows = reference.length + 1

    a = NArray.int(cols, rows)


    for spos in 0..cols-1 do a[spos, 0] = spos * init_gap end
    for rpos in 0..rows-1 do a[0, rpos] = rpos * init_gap end

    spos = 1
    while spos < cols do
      rpos = 1
      while rpos < rows do
        match = a[spos-1,rpos-1] + (sequence[spos-1] != reference[rpos-1] ? diff : same)
        skip_sequence = a[spos-1,rpos] + gap
        skip_reference = a[spos,rpos-1] + gap
        a[spos,rpos] = [match, skip_sequence, skip_reference].max
        rpos += 1
      end
      spos += 1
    end

    start = Misc.max(a[-1,0..rows-1])
    start_pos = a[-1,0..rows-1].to_a.index start

    ref = ''
    seq = ''
    rpos = start_pos
    spos = cols - 1

    while spos > 0 and rpos > 0
      score = a[spos,rpos]
      score_match = a[spos-1,rpos-1]
      score_skip_reference = a[spos,rpos-1]
      score_skip_sequence = a[spos-1,rpos]

      case
      when score == score_match + (sequence[spos-1] != reference[rpos-1] ? diff : same)
        ref << reference[rpos-1]
        seq << sequence[spos-1]
        spos -= 1
        rpos -= 1
      when score == score_skip_reference + gap
        ref << reference[rpos-1]
        seq << '-'
        rpos -= 1
      when score == score_skip_sequence + gap
        seq << sequence[spos-1]
        ref << '-'
        spos -= 1
      else
        raise "stop"
      end
    end

    while (rpos > 0)
      ref << reference[rpos-1]
      seq = seq << '-'
      rpos -= 1    
    end

    while (spos > 0)
      seq << sequence[spos-1]
      ref = ref + '-'
      spos -= 1
    end
    
    [ref.reverse + reference[start_pos..-1], seq.reverse + '-' * (rows - start_pos - 1)]
  end

  def self.IUPAC_to_base(iupac)
    IUPAC2BASE[iupac]
  end

  def self.is_filename?(string)
    return true if Path === string
    return true if String === string and string.length < 265 and File.exists? string
    return false
  end

  def self.intersect_sorted_arrays(a1, a2)
    e1, e2 = a1.shift, a2.shift
    intersect = []
    while true
      break if e1.nil? or e2.nil?
      case e1 <=> e2
      when 0
        intersect << e1
        e1, e2 = a1.shift, a2.shift
      when -1
        e1 = a1.shift while not e1.nil? and e1 < e2
      when 1
        e2 = a2.shift
        e2 = a2.shift while not e2.nil? and e2 < e1
      end
    end
    intersect
  end

  def self.merge_sorted_arrays(a1, a2)
    e1, e2 = a1.shift, a2.shift
    new = []
    while true
      case
      when (e1 and e2)
        case e1 <=> e2
        when 0
          new << e1 
          e1, e2 = a1.shift, a2.shift
        when -1
          new << e1
          e1 = a1.shift
        when 1
          new << e2
          e2 = a2.shift
        end
      when e2
        new << e2
        new.concat a2
        break
      when e1
        new << e1
        new.concat a1
        break
      else
        break
      end
    end
    new
  end

  def self.array2hash(array, default = nil)
    hash = {}
    array.each do |key, value|
      value = default.dup if value.nil? and not default.nil?
      hash[key] = value
    end
    hash
  end

  def self.zip2hash(list1, list2)
    hash = {}
    list1.each_with_index do |e,i|
      hash[e] = list2[i]
    end
    hash
  end

  def self.process_to_hash(list)
    result = yield list
    zip2hash(list, result)
  end

  def self.env_add(var, value, sep = ":", prepend = true)
    ENV[var] ||= ""
    return if ENV[var] =~ /(#{sep}|^)#{Regexp.quote value}(#{sep}|$)/
      if prepend
        ENV[var] = value + sep + ENV[var]
      else
        ENV[var] += sep + ENV[var]
      end
  end

  def self.benchmark(repeats = 1)
    require 'benchmark'
    res = nil
    begin
      measure = Benchmark.measure do
        repeats.times do
          res = yield
        end
      end
      puts "Benchmark for #{ repeats } repeats"
      puts measure
    rescue Exception
      puts "Benchmark aborted"
      raise $!
    end
    res
  end

  def self.profile_html(options = {})
    require 'ruby-prof'
    RubyProf.start
    begin
      res = yield
    rescue Exception
      puts "Profiling aborted"
      raise $!
    ensure
      result = RubyProf.stop
      printer = RubyProf::MultiPrinter.new(result)
      TmpFile.with_file do |dir|
        FileUtils.mkdir_p dir unless File.exists? dir
        printer.print(:path => dir, :profile => 'profile')
        CMD.cmd("firefox  -no-remote  '#{ dir }'")
      end
    end

    res
  end

  def self.profile_graph(options = {})
    require 'ruby-prof'
    RubyProf.start
    begin
      res = yield
    rescue Exception
      puts "Profiling aborted"
      raise $!
    ensure
      result = RubyProf.stop
      #result.eliminate_methods!([/annotated_array_clean_/])
      printer = RubyProf::GraphPrinter.new(result)
      printer.print(STDOUT, options)
    end

    res
  end

  def self.profile(options = {})
    require 'ruby-prof'
    RubyProf.start
    begin
      res = yield
    rescue Exception
      puts "Profiling aborted"
      raise $!
    ensure
      result = RubyProf.stop
      printer = RubyProf::FlatPrinter.new(result)
      printer.print(STDOUT, options)
    end

    res
  end

  def self.memprof
    require 'memprof'
    Memprof.start
    begin
      res = yield
    rescue Exception
      puts "Profiling aborted"
      raise $!
    ensure
      Memprof.stop
      print Memprof.stats
    end

    res
  end

  def self.do_once(&block)
    return nil if $__did_once
    $__did_once = true
    yield
    nil
  end

  def self.reset_do_once
    $__did_once = false
  end

  def self.insist(times = 3, sleep = nil)
    try = 0
    begin
      yield
    rescue
      Log.warn("Insisting after exception: #{$!.message}")
      sleep sleep if sleep
      try += 1
      retry if try < times
      raise $!
    end
  end

  def self.try3times(&block)
    insist(3, &block)
  end

  def self.hash2string(hash)
    hash.sort_by{|k,v| k.to_s}.collect{|k,v| 
      next unless %w(Symbol String Float Fixnum Integer TrueClass FalseClass Module Class Object).include? v.class.to_s
      [ Symbol === k ? ":" << k.to_s : k,
        Symbol === v ? ":" << v.to_s : v] * "="
    }.compact * "#"
  end

  def self.GET_params2hash(string)
    hash = {}
    string.split('&').collect{|item|
      key, value = item.split("=").values_at 0, 1
      hash[key] = value.nil? ? "" : CGI.unescape(value)
    }
    hash
  end

  def self.hash2GET_params(hash)
    hash.sort_by{|k,v| k.to_s}.collect{|k,v| 
      next unless %w(Symbol String Float Fixnum Integer TrueClass FalseClass Module Class Object Array).include? v.class.to_s
      v = case 
          when Symbol === v
            v.to_s
          when Array === v
            v * ","
          else
            CGI.escape(v.to_s)
          end
      [ Symbol === k ? k.to_s : k,  v] * "="
    }.compact * "&"
  end

  def self.hash_to_html_tag_attributes(hash)
    return "" if hash.nil? or hash.empty?
    hash.collect{|k,v| 
      case 
      when (k.nil? or v.nil? or (String === v and v.empty?))
        nil
      when Array === v
        [k,"'" << v * " " << "'"] * "="
      when String === v
        [k,"'" << v << "'"] * "="
      when Symbol === v
        [k,"'" << v.to_s << "'"] * "="
      when TrueClass === v
        [k,"'" << v.to_s << "'"] * "="
      when (Fixnum === v or Float === v)
        [k,"'" << v.to_s << "'"] * "="
      else
        nil
      end
    }.compact * " "
  end

  def self.html_tag(tag, content = nil, params = {})
    attr_str = hash_to_html_tag_attributes(params)
    attr_str = " " << attr_str if String === attr_str and attr_str != ""
    html = if content.nil?
      "<#{ tag }#{attr_str}/>"
    else
      "<#{ tag }#{attr_str}>#{ content }</#{ tag }>"
    end

    html
  end

  def self.path_relative_to(basedir, path)
    path = File.expand_path(path)
    basedir = File.expand_path(basedir)

    case
    when path == basedir
      "."
    when path =~ /#{Regexp.quote basedir}\/(.*)/
      return $1
    else
      return nil
    end
  end

  def self.hostname
    @hostanem ||= `hostname`.strip
  end

  def self.lock(file, *args)
    return yield file, *args if file.nil?
    FileUtils.mkdir_p File.dirname(File.expand_path(file)) unless File.exists?  File.dirname(File.expand_path(file))

    res = nil

    lockfile = Lockfile.new(File.expand_path(file + '.lock'))

    begin
      if File.exists? lockfile and
        Misc.hostname == (info = YAML.load_file(lockfile))["host"] and 
        info["pid"] and not Misc.pid_exists?(info["pid"])

        Log.info("Removing lockfile: #{lockfile}. This pid #{Process.pid}. Content: #{info.inspect}")
        FileUtils.rm lockfile 
      end
    rescue
      Log.warn("Error checking lockfile #{lockfile}: #{$!.message}. Removing. Content: #{begin Open.read(lockfile) rescue "Could not open file" end}")
      FileUtils.rm lockfile if File.exists? lockfile 
    end

    lockfile.lock do 
      res = yield file, *args
    end

    res
  end

  LOCK_REPO_SERIALIZER=Marshal

  def self.lock_in_repo(repo, key, *args)
    return yield file, *args if repo.nil? or key.nil?

    lock_key = "lock-" << key

    begin
      if repo[lock_key] and
        Misc.hostname == (info = LOCK_REPO_SERIALIZER.load(repo[lock_key]))["host"] and 
        info["pid"] and not Misc.pid_exists?(info["pid"])

        Log.info("Removing lockfile: #{lock_key}. This pid #{Process.pid}. Content: #{info.inspect}")
        repo.out lock_key 
      end
    rescue
      Log.warn("Error checking lockfile #{lock_key}: #{$!.message}. Removing. Content: #{begin repo[lock_key] rescue "Could not open file" end}")
      repo.out lock_key if repo.include? lock_key
    end

    while repo[lock_key]
      sleep 1
    end
    
    repo[lock_key] = LOCK_REPO_SERIALIZER.dump({:hostname => Misc.hostname, :pid => Process.pid})

    res = yield lock_key, *args

    repo.delete lock_key

    res
  end

  def self.common_path(dir, file)
    file = File.expand_path file
    dir = File.expand_path dir

    return true if file == dir
    while File.dirname(file) != file
      file = File.dirname(file)
      return true if file == dir
    end

    return false
  end

  def self.in_dir(dir)
    old_pwd = FileUtils.pwd
    res = nil
    begin
      FileUtils.mkdir_p dir unless File.exists? dir
      FileUtils.cd dir
      res = yield
    rescue
      raise $!
    ensure
      FileUtils.cd old_pwd
    end
    res
  end

  def self.to_utf8(string)
    string.encode("UTF-16BE", :invalid => :replace, :undef => :replace, :replace => "?").encode('UTF-8')
  end

  def self.fixutf8(string)
    return string if (string.respond_to? :valid_encoding? and string.valid_encoding?) or
    (string.respond_to? :valid_encoding and string.valid_encoding)
    if string.respond_to?(:encode)
      string.encode("UTF-16BE", :invalid => :replace, :undef => :replace, :replace => "?").encode('UTF-8')
    else
      require 'iconv'
      @@ic ||= Iconv.new('UTF-8//IGNORE', 'UTF-8')
      @@ic.iconv(string)
    end
  end

  def self.fixascii(string)
    if string.respond_to?(:encode)
      self.fixutf8(string).encode("ASCII-8BIT") 
    else
      string
    end
  end

  def self.sensiblewrite(path, content)
    Misc.lock path + '.sensible_write' do
      if not File.exists? path
        begin
          tmp_path = path + '.tmp'
          case
          when String === content
            File.open(tmp_path, 'w') do |f|  f.write content  end
          when (IO === content or StringIO === content)
            File.open(tmp_path, 'w') do |f|  while l = content.gets; f.write l; end  end
        else
          File.open(tmp_path, 'w') do |f|  end
        end
        FileUtils.mv tmp_path, path
      rescue Interrupt
        FileUtils.rm_f tmp_path if File.exists? tmp_path
        FileUtils.rm_f path if File.exists? path
        raise "Interrupted (Ctrl-c)"
      rescue Exception
        FileUtils.rm_f tmp_path if File.exists? tmp_path
        FileUtils.rm_f path if File.exists? path
        raise $!
      end
    end
  end
  end

  def self.add_defaults(options, defaults = {})
    case
    when Hash === options
      new_options = options.dup
    when String === options
      new_options = string2hash options
    else
      raise "Format of '#{options.inspect}' not understood. It should be a hash"
    end

    defaults.each do |key, value|
      next if options.include? key

      new_options[key] = value 
    end

    new_options
  end

  def self.digest(text)
    Digest::MD5.hexdigest(text)
  end

  HASH2MD5_MAX_STRING_LENGTH = 1000
  HASH2MD5_MAX_ARRAY_LENGTH = 100
  def self.hash2md5(hash)
    str = ""
    keys = hash.keys
    keys = keys.clean_annotations if keys.respond_to? :clean_annotations
    keys = keys.sort_by{|k| k.to_s}

    if hash.respond_to? :unnamed
      unnamed = hash.unnamed
      hash.unnamed = true 
    end
    keys.each do |k|
      next if k == :monitor or k == "monitor" or k == :in_situ_persistence or k == "in_situ_persistence"
      v = hash[k]
      case
      when TrueClass === v
        str << k.to_s << "=>true" 
      when FalseClass === v
        str << k.to_s << "=>false" 
      when Hash === v
        str << k.to_s << "=>" << hash2md5(v)
      when Symbol === v
        str << k.to_s << "=>" << v.to_s
      when (String === v and v.length > HASH2MD5_MAX_STRING_LENGTH)
        str << k.to_s << "=>" << v[0..HASH2MD5_MAX_STRING_LENGTH] << "; #{ v.length }"
      when String === v
        str << k.to_s << "=>" << v
      when (Array === v and v.length > HASH2MD5_MAX_ARRAY_LENGTH)
        str << k.to_s << "=>[" << v[0..HASH2MD5_MAX_ARRAY_LENGTH] * "," << "; #{ v.length }]"
      when Array === v
        str << k.to_s << "=>[" << v * "," << "]"
      else
        v_ins = v.inspect

        case
        when v_ins =~ /:0x0/
          str << k.to_s << "=>" << v_ins.sub(/:0x[a-f0-9]+@/,'')
        else
          str << k.to_s << "=>" << v_ins
        end

      end

      str << "_" << hash2md5(v.info) if Annotated === v
    end
    hash.unnamed = unnamed if hash.respond_to? :unnamed

    if str.empty?
      ""
    else
      digest(str)
    end
  end

  def self.process_options(hash, *keys)
    if keys.length == 1
      hash.include?(keys.first.to_sym) ? hash.delete(keys.first.to_sym) : hash.delete(keys.first.to_s) 
    else
      keys.collect do |key| hash.include?(key.to_sym) ? hash.delete(key.to_sym) : hash.delete(key.to_s) end
    end
  end

  def self.pull_keys(hash, prefix)
    new = {}
    hash.keys.each do |key|
      if key.to_s =~ /#{ prefix }_(.*)/
        case
        when String === key
          new[$1] = hash.delete key
        when Symbol === key
          new[$1.to_sym] = hash.delete key
        end
      else
        if key.to_s == prefix.to_s
          new[key] = hash.delete key
        end
      end
    end

    new
  end

  def self.string2const(string)
    return nil if string.nil?
    mod = Kernel

    string.to_s.split('::').each do |str|
      mod = mod.const_get str
    end

    mod
  end

  def self.string2hash(string)

    options = {}
    string.split(/#/).each do |str|
      if str.match(/(.*)=(.*)/)
        option, value = $1, $2
      else
        option, value = str, true
      end

    option = option.sub(":",'').to_sym if option.chars.first == ':'
    value  = value.sub(":",'').to_sym if String === value and value.chars.first == ':'

    if value == true
      options[option] = option.to_s.chars.first != '!' 
    else
      options[option] = Thread.start do
        $SAFE = 0;
        case 
        when value =~ /^(?:true|T)$/i
          true
        when value =~ /^(?:false|F)$/i
          false
        when Symbol === value
          value
        when (String === value and value =~ /^\/(.*)\/$/)
          Regexp.new /#{$1}/
        else
          begin
            Kernel.const_get value
          rescue
            begin  
              raise if value =~ /[a-z]/ and defined? value
              eval(value) 
            rescue Exception
              value 
            end
          end
        end
      end.value
    end
    end

    options
  end

  def self.field_position(fields, field, quiet = false)
    return field if Integer === field or Range === field
    raise FieldNotFoundError, "Field information missing" if fields.nil? && ! quiet
    fields.each_with_index{|f,i| return i if f == field}
    field_re = Regexp.new /^#{field}$/i
    fields.each_with_index{|f,i| return i if f =~ field_re}
    raise FieldNotFoundError, "Field #{ field.inspect } was not found" unless quiet
  end

  # Divides the array into +num+ chunks of the same size by placing one
  # element in each chunk iteratively.
  def self.divide(array, num)
    chunks = []
    num.to_i.times do chunks << [] end
    array.each_with_index{|e, i|
      c = i % num
      chunks[c] << e
    }
    chunks
  end

  # Divides the array into chunks of +num+ same size by placing one
  # element in each chunk iteratively.
  def self.ordered_divide(array, num)
    last = array.length - 1
    chunks = []
    current = 0
    while current <= last
      next_current = [last, current + num - 1].min
      chunks << array[current..next_current]
      current = next_current + 1
    end
    chunks
  end

  def self.zip_fields(array)
    return [] if array.empty?
    array[0].zip(*array[1..-1])
  end

  def self.snake_case(string)
    return nil if string.nil?
    string.
      gsub(/([A-Z]{2,})([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z])([A-Z])/,'\1_\2').
      gsub(/\s/,'_').gsub(/[^\w_]/, '').
      split("_").collect{|p| p.match(/[A-Z]{2,}/) ? p : p.downcase } * "_"
  end

  # source: https://gist.github.com/ekdevdes/2450285
  # author: Ethan Kramer (https://github.com/ekdevdes)
  def self.humanize(value, options = {})
    if options.empty?
      options[:format] = :sentence
    end

    values = []
    values = value.split('_')
    values.each_index do |index|
      # lower case each item in array
      # Miguel Vazquez edit: Except for acronyms
      values[index].downcase! unless values[index].match(/[a-zA-Z][A-Z]/)
    end
    if options[:format] == :allcaps
      values.each do |value|
        value.capitalize!
      end

      if options.empty?
        options[:seperator] = " "
      end

      return values.join " "
    end

    if options[:format] == :class
      values.each do |value|
        value.capitalize!
      end

      return values.join ""
    end

    if options[:format] == :sentence
      values[0].capitalize! unless values[0].match(/[a-zA-Z][A-Z]/)

      return values.join " "
    end

    if options[:format] == :nocaps
      return values.join " "
    end
  end
end

class RBBTError < StandardError
  attr_accessor :info

  alias old_to_s to_s
  def to_s
    str = old_to_s.dup
    if info
      str << "\n" << "Additional Info:\n---\n" << info << "---"
    end
    str
  end
end

module IndiferentHash
  extend ChainMethods
  self.chain_prefix = :indiferent

  def indiferent_get_brackets(key)
    case 
    when (Symbol === key and indiferent_clean_include? key)
      indiferent_clean_get_brackets(key)
    when (Symbol === key and indiferent_clean_include? key.to_s)
      indiferent_clean_get_brackets(key.to_s)
    when (String === key and indiferent_clean_include? key)
      indiferent_clean_get_brackets(key)
    when (String === key and indiferent_clean_include? key.to_sym)
      indiferent_clean_get_brackets(key.to_sym)
    else
      indiferent_clean_get_brackets(key) 
    end
  end

  def indiferent_values_at(*key_list)
    res = []
    key_list.each{|key| res << indiferent_get_brackets(key)}
    res
  end

  def indiferent_include?(key)
    case
    when Symbol === key
      indiferent_clean_include?(key) or indiferent_clean_include?(key.to_s) 
    when String === key
      indiferent_clean_include?(key) or indiferent_clean_include?(key.to_sym) 
    else
      indiferent_clean_include?(key)
    end
  end

  def indiferent_delete(value)
    if indiferent_clean_include? value.to_s
      indiferent_clean_delete(value.to_s) 
    else
      indiferent_clean_delete(value.to_sym) 
    end
  end

  def self.setup(hash)
    return hash if IndiferentHash === hash
    hash.extend IndiferentHash unless IndiferentHash === hash
    hash
  end
end

module PDF2Text
  def self.pdftotext(filename, options = {})
    require 'rbbt/util/cmd'
    require 'rbbt/util/tmpfile'
    require 'rbbt/util/open'


    TmpFile.with_file(Open.open(filename, options.merge(:nocache => true)).read) do |pdf_file|
      CMD.cmd("pdftotext #{pdf_file} -", :pipe => false, :stderr => true)
    end
  end
end
