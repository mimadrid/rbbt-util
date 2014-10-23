module Misc

  def self.add_libdir(dir=nil)
    dir ||= File.join(Path.caller_lib_dir(caller.first), 'lib')
    $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include? dir
  end

  def self.pre_fork
    Persist::CONNECTIONS.values.each do |db| iii db.persistence_path; db.close if db.write? end
    ObjectSpace.each_object(Mutex) do |m| 
      begin 
        m.unlock 
      rescue ThreadError
      end if m.locked? 
    end
  end

  def self.string2const(string)
    return nil if string.nil?
    mod = Kernel

    string.to_s.split('::').each do |str|
      mod = mod.const_get str
    end

    mod
  end

  def self.benchmark(repeats = 1, message = nil)
    require 'benchmark'
    res = nil
    begin
      measure = Benchmark.measure do
        repeats.times do
          res = yield
        end
      end
      if message
        puts "#{message }: #{ repeats } repeats"
      else
        puts "Benchmark for #{ repeats } repeats"
      end
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

  def self.insist(times = 3, sleep = nil, msg = nil)
    if Array === times
      sleep_array = times
      times = sleep_array.length
      sleep = sleep_array.shift
    end
    try = 0
    begin
      yield
    rescue TryAgain
      sleep sleep
      retry
    rescue Aborted, Interrupt
      if msg
        Log.warn("Not Insisting after Aborted: #{$!.message} -- #{msg}")
      else
        Log.warn("Not Insisting after Aborted: #{$!.message}")
      end
      raise $!
    rescue Exception
      if msg
        Log.warn("Insisting after exception: #{$!.class} #{$!.message} -- #{msg}")
      else
        Log.warn("Insisting after exception:  #{$!.class} #{$!.message}")
      end 

      if sleep and try > 0
        sleep sleep
        sleep = sleep_array.shift if sleep_array
      else
        Thread.pass
      end

      try += 1
      retry if try < times
      raise $!
    end
  end

  def self.try3times(&block)
    insist(3, &block)
  end

  # Divides the array into +num+ chunks of the same size by placing one
  # element in each chunk iteratively.
  def self.divide(array, num)
    num = 1 if num == 0
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

  def self.object_delta(*args)
    res, delta = nil, nil
    Thread.exclusive do
      pre = Set.new
      delta = Set.new

      GC.start
      ObjectSpace.each_object(*args) do |o|
        pre.add o
      end

      res = yield

      GC.start
      ObjectSpace.each_object(*args) do |o|
        delta.add o unless pre.include? o
      end

    end
    Log.info "Delta: #{delta.inspect}" 
    res
  end

  def self.time_tick
    if $_last_time_tick.nil?
      $_last_time_tick = Time.now
      puts "Tick started: #{Time.now}"
    else
      ellapsed = Time.now - $_last_time_tick
      puts "Tick ellapsed: #{ellapsed.to_i} s. #{(ellapsed * 1000).to_i - ellapsed.to_i * 1000} ms"
      $_last_time_tick = Time.now
    end
  end

  def self.bootstrap(elems, num = :current, options = {}, &block)
    IndiferentHash.setup options
    num = :current if num.nil?
    cpus = case num
           when :current
            10
           when String
             num.to_i
           when Integer
             if num < 100
               num
             else
               32000 / num
             end
           else
             raise "Parameter 'num' not understood: #{Misc.fingerprint num}"
           end


    options = Misc.add_defaults options, :respawn => true, :cpus => cpus, :into => Set.new 
    options = Misc.add_defaults options, :bar => "Bootstrap in #{ options[:cpus] } cpus: #{ Misc.fingerprint Annotated.purge(elems) }"
    respawn = options[:respawn] and options[:cpus] and options[:cpus].to_i > 1

    index = (0..elems.length-1).to_a.collect{|v| v.to_s }
    TSV.traverse index, options do |pos|
      elem = elems[pos.to_i]
      elems.annotate elem if elems.respond_to? :annotate
      begin
        yield elem
      rescue Interrupt
        Log.warn "Process #{Process.pid} was aborted"
      end
      raise RbbtProcessQueue::RbbtProcessQueueWorker::Respawn if respawn == :always and cpus > 1
      nil
    end
  end

  def self.memory_use(pid=nil)
    `ps -o rss -p #{pid || $$}`.strip.split.last.to_i
  end
end
