require 'rbbt/util/open' 
require 'yaml'

class Step
   
  INFO_SERIALIAZER = Marshal

  def self.started?
    info_file.exists?
  end
  
  def self.wait_for_jobs(jobs)
    begin
      threads = []
      jobs.each do |j| threads << Thread.new{j.grace.join} end
      threads.each{|t| t.join }
    rescue Exception
      threads.each{|t| t.exit }
      jobs.each do |j| j.abort end
      raise $!
    end
  end

  def self.files_dir(path)
    path.nil? ? nil : path + '.files'
  end

  def self.info_file(path)
    path.nil? ? nil : path + '.info'
  end

  def self.step_info(path)
    begin
      Open.open(info_file(path)) do |f|
        INFO_SERIALIAZER.load(f)
      end
    rescue Exception
      Log.exception $!
      {}
    end
  end

  def self.job_name_for_info_file(info_file, extension = nil)
    if extension and not extension.empty?
      info_file.sub(/\.#{extension}\.info$/,'')
    else
      info_file.sub(/\.info$/,'')
    end
  end

  def name
    path.sub(/.*\/#{Regexp.quote task.name.to_s}\/(.*)/, '\1')
  end

  def clean_name
    name.sub(/(.*)_.*/, '\1')
  end

  def task_name
    @task_name ||= task.name
  end

  # {{{ INFO

  def info_file
    @info_file ||= Step.info_file(path)
  end

  def info
    return {} if info_file.nil? or not Open.exists? info_file
    begin
      @info_mutex.synchronize do
        begin
          return @info_cache if @info_cache and File.mtime(info_file) < @info_cache_time
        rescue Exception
          raise $!
        end

        begin
          @info_cache = Misc.insist(2, 3, info_file) do
            Misc.insist(2, 1, info_file) do
              Misc.insist(3, 0.2, info_file) do
                Open.open(info_file) do |file|
                  INFO_SERIALIAZER.load(file) || {}
                end
              end
            end
          end
          @info_cache_time = Time.now
          @info_cache
        end
      end
    rescue Exception
      Log.debug{"Error loading info file: " + info_file}
      Open.write(info_file, INFO_SERIALIAZER.dump({:status => :error, :messages => ["Info file lost"]}))
      raise $!
    end
  end

  def set_info(key, value)
    return nil if @exec or info_file.nil?
    value = Annotated.purge value if defined? Annotated
    lock_filename = Persist.persistence_path(info_file, {:dir => Step.lock_dir})
    Open.lock(info_file, :refresh => false) do
      i = info
      i[key] = value 
      @info_cache = i
      Open.write(info_file, INFO_SERIALIAZER.dump(i))
      @info_cache_time = Time.now
      value
    end
  end

  def merge_info(hash)
    return nil if @exec or info_file.nil?
    value = Annotated.purge value if defined? Annotated
    lock_filename = Persist.persistence_path(info_file, {:dir => Step.lock_dir})
    Open.lock(info_file, :refresh => false) do
      i = info
      i.merge! hash
      @info_cache = i
      Open.write(info_file, INFO_SERIALIAZER.dump(i))
      @info_cache_time = Time.now
      value
    end
  end

  def status
    begin
      info[:status]
    rescue Exception
      Log.error "Exception reading status: #{$!.message}" 
      :error
    end
  end

  def status=(status)
    set_info(:status, status)
  end

  def messages
    if messages = info[:messages]
      messages
    else
      set_info(:messages, []) if self.respond_to?(:set_info)
    end
  end

  def message(message)
    set_info(:messages, (messages || []) << message)
  end

  def self.status_color(status)
    status = status.split(">").last
    case status
    when "starting"
      :yellow
    when "error", "aborted"
      :red
    when "done"
      :green
    else
      :cyan
    end
  end

  def self.log_block(staus, message, path, &block)
    start = Time.now
    status = status.to_s
    status_color = self.status_color status

    Log.info do 
      now = Time.now
      str = Log.color :reset
      str << "#{ Log.color status_color, status}"
      str << ": #{ message }" if message
      str << " -- #{Log.color :blue, path.to_s}" if path
      str << " #{Log.color :yellow, Process.pid}"
      str
    end
    res = yield
    eend = Time.now
    Log.info do 
      now = Time.now
      str = "#{ Log.color :cyan, status.to_s } +#{Log.color :green, "%.1g" % (eend - start)}"
      str << " -- #{Log.color :blue, path.to_s}" if path
      str << " #{Log.color :yellow, Process.pid}"
      str
    end
    res
  end

  def self.log_string(status, message, path)
    Log.info do 

      status = status.to_s
      status_color = self.status_color status

      str = Log.color :reset
      str << "#{ Log.color status_color, status}"
      str << ": #{ message }" if message
      str << " -- #{Log.color :blue, path.to_s}" if path
      str << " #{Log.color :yellow, Process.pid}"
      str
    end
  end

  def self.log_progress(status, options, path, &block)
    options = Misc.add_defaults options, :severity => Log::INFO
    max = Misc.process_options options, :max
    Log::ProgressBar.with_bar(max, options) do |bar|
      begin
        res = yield bar
        raise KeepBar.new res if IO === res
        res
      rescue
        Log.exception $!
      end
    end
  end

  def self.log(status, message, path, &block)
    if block
      if Hash === message
        log_progress(status, message, path, &block)
      else
        log_block(status, message, path, &block)
      end
    else
      log_string(status, message, path)
    end
  end

  def log(status, message = nil, &block)
    self.status = status
    self.message Log.uncolor(message)
    Step.log(status, message, path, &block)
  end

  def exception(ex, msg = nil)
    self._abort
    ex_class = ex.class.to_s
    set_info :backtrace, ex.backtrace
    set_info :exception, {:class => ex_class, :message => ex.message, :backtrace => ex.backtrace}
    if msg.nil?
      log :error, "#{ex_class} -- #{ex.message}"
    else
      log :error, "#{msg} -- #{ex.message}"
    end
  end

  def started?
    Open.exists? info_file or Open.exists? path
  end

  def done?
    path and File.exists? path
  end

  def streaming?
    IO === @result or status == :streaming
  end

  def running?
    return nil if not Open.exists? info_file
    return nil if info[:pid].nil?

    pid = @pid || info[:pid]
    return Misc.pid_exists?(pid) 
  end

  def error?
    status == :error
  end

  def aborted?
    @aborted || status == :aborted
  end

  # {{{ INFO

  def files_dir
    @files_dir ||= Step.files_dir path
  end

  def files
    files = Dir.glob(File.join(files_dir, '**', '*')).reject{|path| File.directory? path}.collect do |path| 
      Misc.path_relative_to(files_dir, path) 
    end
    files
  end

  def file(name)
    Path.setup(File.join(files_dir, name.to_s))
  end

  def save_file(name, content)
    content = case
              when String === content
                content
              when Array === content
                content * "\n"
              when TSV === content
                content.to_s
              when Hash === content
                content.collect{|*p| p * "\t"} * "\n"
              else
                content.to_s
              end
    Open.write(file(name), content)
  end

  def load_file(name, type = nil, options = {})
    if type.nil? and name =~ /.*\.(\w+)$/
      extension = name.match(/.*\.(\w+)$/)[1]
      case extension
      when "tc"
        type = :tc
      when "tsv"
        type = :tsv
      when "list", "ary", "array"
        type = :array
      when "yaml"
        type = :yaml
      when "marshal"
        type = :marshal
      else
        type = :other
      end
    else
      type ||= :other
    end

    case type.to_sym
    when :tc
      Persist.open_tokyocabinet(file(name), false)
    when :tsv
      TSV.open Open.open(file(name)), options
    when :array
      #Open.read(file(name)).split /\n|,\s*/
      Open.read(file(name)).split "\n"
    when :yaml
      YAML.load(Open.open(file(name)))
    when :marshal
      Marshal.load(Open.open(file(name)))
    else
      Open.read(file(name))
    end
  end

  def provenance
    provenance = {}
    dependencies.each do |dep|
      next unless dep.path.exists?
      if File.exists? dep.info_file
        provenance[dep.path] = dep.provenance if File.exists? dep.path
      else
        provenance[dep.path] = nil
      end
    end
    {:inputs => info[:inputs], :provenance => provenance}
  end

  def provenance_paths
    provenance = {}
    dependencies.each do |dep|
      provenance[dep.path] = dep.provenance_paths if File.exists? dep.path
    end
    provenance
  end
end

module Workflow

  def log(status, message = nil, &block)
    Step.log(status, message, nil, &block)
  end

  def task_info(name)
    name = name.to_sym
    task = tasks[name]
    description = task.description
    result_description = task.result_description
    result_type = task.result_type
    inputs = rec_inputs(name).uniq
    input_types = rec_input_types(name)
    input_descriptions = rec_input_descriptions(name)
    input_defaults = rec_input_defaults(name)
    input_options = rec_input_options(name)
    export = case
             when (synchronous_exports.include?(name.to_sym) or synchronous_exports.include?(name.to_s))
               :synchronous
             when (asynchronous_exports.include?(name.to_sym) or asynchronous_exports.include?(name.to_s))
               :asynchronous
             when (exec_exports.include?(name.to_sym) or exec_exports.include?(name.to_s))
               :exec
             else
               :none
             end


    dependencies = task_dependencies[name].select{|dep| String === dep or Symbol === dep}
    { :id => File.join(self.to_s, name.to_s),
      :description => description,
      :export => export,
      :inputs => inputs,
      :input_types => input_types,
      :input_descriptions => input_descriptions,
      :input_defaults => input_defaults,
      :input_options => input_options,
      :result_type => result_type,
      :result_description => result_description,
      :dependencies => dependencies
    }
  end

  def rec_dependencies(taskname)
    if task_dependencies.include? taskname
      deps = task_dependencies[taskname].select{|dep| String === dep or Symbol === dep or Array === dep}
      all_deps = deps.dup
      deps.each do |dep| 
        if Array === dep 
          dep.first.rec_dependencies(dep.last).each do |d|
            if Array === d
              all_deps << d
            else
              all_deps << [dep.first, d]
            end
          end
        else
          all_deps.concat rec_dependencies(dep.to_sym)
        end
      end
      all_deps.uniq
    else
      []
    end
  end

  def rec_inputs(taskname)
    [taskname].concat(rec_dependencies(taskname)).inject([]){|acc, tn| acc.concat((Array === tn ? tn.first.tasks[tn.last] : tasks[tn.to_sym]).inputs) }.uniq
  end

  def rec_input_defaults(taskname)
    [taskname].concat(rec_dependencies(taskname)).inject({}){|acc, tn| acc.merge((Array === tn ? tn.first.tasks[tn.last.to_sym] : tasks[tn.to_sym]).input_defaults) }.
      tap{|h| IndiferentHash.setup(h)}
  end

  def rec_input_types(taskname)
    [taskname].concat(rec_dependencies(taskname)).inject({}){|acc, tn| acc.merge((Array === tn ? tn.first.tasks[tn.last.to_sym] : tasks[tn.to_sym]).input_types) }.
      tap{|h| IndiferentHash.setup(h) }
  end

  def rec_input_descriptions(taskname)
    [taskname].concat(rec_dependencies(taskname)).inject({}){|acc, tn| acc.merge((Array === tn ? tn.first.tasks[tn.last.to_sym] : tasks[tn.to_sym]).input_descriptions) }.
      tap{|h| IndiferentHash.setup(h)}
  end

  def rec_input_options(taskname)
    [taskname].concat(rec_dependencies(taskname)).inject({}){|acc, tn| acc.merge((Array === tn ? tn.first.tasks[tn.last.to_sym] : tasks[tn.to_sym]).input_options)}.
      tap{|h| IndiferentHash.setup(h)}
  end

  def real_dependencies(task, jobname, inputs, dependencies)
    real_dependencies = []
    dependencies.each do |dependency|
      real_dependencies << case dependency
      when Array
        dependency.first.job(dependency.last, jobname, inputs)
      when Step
        dependency
      when Symbol
        job(dependency, jobname, inputs)
      when Proc
        dependency.call jobname, inputs
      end
    end
    real_dependencies.flatten.compact
  end

  TAG = :hash
  def step_path(taskname, jobname, inputs, dependencies, extension = nil)
    #Proc.new{
      raise "Jobname makes an invalid path: #{ jobname }" if jobname =~ /\.\./
      if inputs.any? or dependencies.any?
        tagged_jobname = case TAG
                         when :hash
                           input_str = ""
                           input_str << inputs.collect{|i| Misc.fingerprint(i) } * "," 
                           input_str << ";" << dependencies.collect{|dep| dep.name } * "\n"
                           jobname + '_' << Misc.digest(input_str)
                         else
                           jobname
                         end
      else
        tagged_jobname = jobname
      end

      if extension and not extension.empty?
        tagged_jobname = tagged_jobname + ('.' << extension.to_s)
      end

      workdir[taskname][tagged_jobname].find
    #}
  end

  def id_for(path)
    if workdir.respond_to? :find
      workdir_find = workdir.find 
    else
      workdir_find = workdir
    end
    Misc.path_relative_to workdir_find, path
  end

  def task_for(path)
    if workdir.respond_to? :find
      workdir_find = workdir.find 
    else
      workdir_find = workdir
    end
 
    workdir_find = File.expand_path(workdir_find)
    path = File.expand_path(path)
    dir = File.dirname(path)
    Misc.path_relative_to(workdir_find, dir).sub(/([^\/]+)\/.*/,'\1')
  end
end
