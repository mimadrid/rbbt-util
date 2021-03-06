
class Step

  STREAM_CACHE = {}
  STREAM_CACHE_MUTEX = Mutex.new
  def self.purge_stream_cache
    Log.debug "Purging dup. stream cache"
    STREAM_CACHE_MUTEX.synchronize do
      #STREAM_CACHE.collect{|k,s| 
      #  Thread.new do
      #    Misc.consume_stream s
      #  end
      #}
      STREAM_CACHE.clear
    end
  end

  def self.dup_stream(stream)
    case stream
    when IO, File, Step
      return stream if stream.respond_to?(:closed?) and stream.closed?
      return stream if stream.respond_to?(:done?) and stream.done?

      STREAM_CACHE_MUTEX.synchronize do
        stream_key = Misc.fingerprint(stream)
        current = STREAM_CACHE[stream_key]
        case current
        when nil, Step
          Log.medium "Not duplicating stream #{stream_key}"
          STREAM_CACHE[stream_key] = stream
        when File
          if Open.exists? current.path 
            Log.medium "Reopening file #{stream_key}"
            Open.open(current.path)
          else
            new = Misc.dup_stream(current)
            Log.medium "Duplicating file #{stream_key} #{current.inspect} => #{Misc.fingerprint(new)}"
            new
          end
        else
          new = Misc.dup_stream(current)
          Log.medium "Duplicating stream #{stream_key} #{ Misc.fingerprint(stream) } => #{Misc.fingerprint(new)}"
          new
        end
      end
    when TSV::Dumper#, TSV::Parser
      stream = stream.stream
      return stream if stream.closed?

      STREAM_CACHE_MUTEX.synchronize do
        if STREAM_CACHE[stream].nil?
          Log.high "Not duplicating dumper #{ stream.inspect }"
          STREAM_CACHE[stream] = stream
        else
          new = Misc.dup_stream(STREAM_CACHE[stream])
          Log.high "Duplicating dumper #{ stream.inspect } into #{new.inspect}"
          new
        end
      end
    else
      stream
    end
  end

  def dup_inputs
    return if @dupped or ENV["RBBT_NO_STREAM"] == 'true'
    Log.low "Dupping inputs for #{path}"
    dupped_inputs = @inputs.collect do |input|
      Step.dup_stream input
    end
    @inputs.replace dupped_inputs
    @dupped = true
  end

  def self.prepare_for_execution(job)
    return if job.done? && ! job.dirty?

    status = job.status.to_s
    if defined? WorkflowRESTClient && WorkflowRESTClient::RemoteStep === job 
      return if ! (status == 'done' and status == 'error' and status == 'aborted')
    else
      return if status == 'streaming' && job.running?
    end

    if (status == 'error' || job.aborted?) && job.recoverable_error?
      job.clean 
    end

    job.dup_inputs unless status == 'done' or job.started?

    raise DependencyError, job if job.error?
  end

  def log_dependency_exec(dependency, action)
    task_name = self.task_name

    str = Log.color(:reset, "")
    str << Log.color(:yellow, task_name.to_s || "") 
    str << " "
    str << Log.color(:magenta, action.to_s)
    str << " "
    str << Log.color(:yellow, dependency.task_name.to_s || "")
    str << " -- "
    str << "#{Log.color :blue, dependency.path}"

    Log.info str
  end

  def execute_dependency(dependency, log = true)
    task_name = self.task_name
    begin

      dependency.resolve_input_steps

      if dependency.done?
        dependency.inputs.each do |v|
          Misc.consume_stream(v) if IO === v
          Misc.consume_stream(TSV.get_stream v) if Step === v and not v.done?  and  v.streaming?
        end
        log_dependency_exec(dependency, :done) if log
        return
      end

      if not dependency.started?
        log_dependency_exec(dependency, :starting)
        dependency.run(true)
        raise TryAgain
      end

      dependency.grace

      if dependency.aborted?
        log_dependency_exec(dependency, "aborted (clean)")
        dependency.clean
        raise TryAgain
      end

      if dependency.error?
        log_dependency_exec(dependency, :error)
        raise DependencyError, [dependency.path, dependency.messages.last] * ": " if dependency.error?
      end

      if dependency.streaming?
        log_dependency_exec(dependency, :streaming) if log
        return
      end

      begin
        log_dependency_exec(dependency, :joining)
        dependency.join
        raise TryAgain unless dependency.done?
      rescue Aborted
        raise TryAgain
      end

    rescue TryAgain
      retry
    rescue Aborted, Interrupt
      Log.error "Aborted dep. #{Log.color :red, dependency.task_name.to_s}"
      raise $!
    rescue Interrupt
      Log.error "Interrupted while in dep. #{Log.color :red, dependency.task_name.to_s}"
      raise $!
    rescue Exception
      Log.error "Exception in dep. #{ Log.color :red, dependency.task_name.to_s } -- #{$!.message}"
      Log.exception $!
      raise $!
    end
  end

  def execute_and_dup(step, dep_step, log = true)
    dup = step.result.nil?
    execute_dependency(step, log)
    if dup and step.streaming? and not step.result.nil?
      if dep_step[step.path] and dep_step[step.path].length > 1
        stream = step.result
        other_steps = dep_step[step.path]
        return unless other_steps.length > 1
        log_dependency_exec(step, "duplicating #{other_steps.length}") 
        copies = Misc.tee_stream_thread_multiple(stream, other_steps.length)
        other_steps.zip(copies).each do |other,dupped_stream|
          stream.annotate(dupped_stream) if stream.respond_to?(:annotate)
          other.instance_variable_set("@result", dupped_stream)
        end
      end
    end
  end

  def run_compute_dependencies(type, list, dep_step = {})
    if Array === type
      type, *rest = type
    end

    case type
    when :produce, :no_dup
      list.each do |step|
        Misc.insist do
          begin
            step.produce
          rescue Exception
            step.abort
            raise $!
          end
        end
        nil
      end
    when :bootstrap
      cpus = rest.nil? ? nil : rest.first 
      cpus = 5 if cpus.nil?
      cpus = list.length / 2 if cpus > list.length / 2

      Misc.bootstrap(list, cpus, :bar => "Bootstrapping dependencies for #{path}", :respawn => :always) do |dep|
        Misc.insist do
          begin
            dep.produce 
            Log.warn "Error in bootstrap dependency #{dep.path}: #{dep.messages.last}" if dep.error? or dep.aborted?
          rescue Aborted
            dep.abort
            Log.warn "Aborted bootstrap dependency #{dep.path}: #{dep.messages.last}" if dep.error? or dep.aborted?
            raise $!
          rescue Exception
            dep.exception $!
            raise StopInsist.new($!)
          end
        end
        nil
      end
    else
      list.each do |step|
        execute_and_dup(step, dep_step, false)
      end
    end
  end

  def run_dependencies
    dep_step = {}

    rec_dependencies = self.rec_dependencies

    return if rec_dependencies.empty?

    all_deps = rec_dependencies + [self]

    dependencies.each do |dep|
      next unless ComputeDependency === dep
      if dep.compute == :produce
        dep.produce 
      end
    end

    compute_deps = rec_dependencies.collect do |dep|
      next unless ComputeDependency === dep
      dep.rec_dependencies
    end.compact.flatten.uniq

    seen_paths = Set.new
    all_deps.uniq.each do |step|
      next if seen_paths.include? step.path
      seen_paths << step.path
      Step.prepare_for_execution(step) unless step == self
      next unless step.dependencies and step.dependencies.any?
      step.dependencies.each do |step_dep|
        next if step_dep.done? or step_dep.running? or (ComputeDependency === step_dep and step_dep.compute == :nodup)
        dep_step[step_dep.path] ||= []
        dep_step[step_dep.path] << step_dep
      end
    end
    
    self.dup_inputs

    required_dep_paths = []
    dep_step.each do |path,list|
      required_dep_paths << path if list.length > 1
    end

    required_dep_paths.concat dependencies.collect{|dep| dep.path }


    log :dependencies, "Dependencies for step #{Log.color :yellow, task.name.to_s || ""}"

    pre_deps = []
    compute_pre_deps = {}
    last_deps = []
    compute_last_deps = {}
    seen_paths = Set.new
    rec_dependencies.uniq.each do |step| 
      next if seen_paths.include? step.path
      seen_paths << step.path
      next unless required_dep_paths.include? step.path
      if dependencies.include?(step) and step.inputs.flatten.select{|i| Step === i}.any?
        if ComputeDependency === step
          compute_last_deps[step.compute] ||= []
          compute_last_deps[step.compute] << step
        else
          last_deps << step
        end
      else
        if ComputeDependency === step
          compute_pre_deps[step.compute] ||= []
          compute_pre_deps[step.compute] << step
        else
          pre_deps << step #if dependencies.include?(step)
        end
      end
    end

    Log.medium "Processing pre dependencies: #{Misc.fingerprint(pre_deps)} - #{Log.color :blue, self.path}" if pre_deps.any?
    pre_deps.each do |step|
      next if compute_deps.include? step
      execute_and_dup(step, dep_step, false)
    end

    Log.medium "Computing pre dependencies: #{Misc.fingerprint(compute_pre_deps)} - #{Log.color :blue, self.path}" if compute_pre_deps.any?
    compute_pre_deps.each do |type,list|
      run_compute_dependencies(type, list, dep_step)
    end

    Log.medium "Processing last dependencies: #{Misc.fingerprint(last_deps)} - #{Log.color :blue, self.path}" if last_deps.any?
    last_deps.each do |step|
      next if compute_deps.include? step
      execute_and_dup(step, dep_step)
    end

    Log.medium "Computing last dependencies: #{Misc.fingerprint(compute_last_deps)} - #{Log.color :blue, self.path}" if compute_last_deps.any?
    compute_last_deps.each do |type,list|
      run_compute_dependencies(type, list, dep_step)
    end

  end

  def stop_dependencies
    return if dependencies.nil?
    dependencies.each do |dep|
      begin
        next if dep.done? or dep.aborted?
      rescue
      end
      dep.abort
    end
    kill_children
  end

end
