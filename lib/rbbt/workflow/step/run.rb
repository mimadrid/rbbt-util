require 'rbbt/workflow/step/dependencies'

class Step

  attr_reader :stream, :dupped, :saved_stream, :inputs

  def get_stream
    @mutex.synchronize do
      Log.low "Getting stream from #{path} #{!@saved_stream} [#{object_id}-#{Misc.fingerprint(@result)}]"
      begin
        return nil if @saved_stream
        if IO === @result 
          @saved_stream = @result 
        else 
          nil
        end
      end
    end
  end

  def resolve_input_steps
    step = false
    pos = 0
    new_inputs = @inputs.collect do |i| 
      begin
        if Step === i
          step = true
          if i.done?
            if (task.input_options[task.inputs[pos]] || {})[:stream]
              TSV.get_stream i
            else
              i.load
            end
          elsif i.streaming?
            TSV.get_stream i
          else
            i.join
            if (task.input_options[task.inputs[pos]] || {})[:stream]
              TSV.get_stream i
            else
              i.load
            end
          end
        else
          i
        end
      ensure
        pos += 1
      end
    end
    @inputs.replace new_inputs if step
  end

  def _exec
    resolve_input_steps
    @exec = true if @exec.nil?
    @task.exec_in((bindings ? bindings : self), *@inputs)
  end

  def exec(no_load=false)
    dependencies.each{|dependency| dependency.exec(no_load) }
    @mutex.synchronize do
      @result = self._exec
      @result = @result.stream if TSV::Dumper === @result
    end
    (no_load or ENV["RBBT_NO_STREAM"]) ? @result : prepare_result(@result, @task.result_description)
  end

  def checks
    rec_dependencies.collect{|dependency| (defined? WorkflowRESTClient and WorkflowRESTClient::RemoteStep === dependency) ? nil : dependency.path }.compact.uniq
  end

  def kill_children
    begin
      children_pids = info[:children_pids]
      if children_pids and children_pids.any?
        Log.medium("Killing children: #{ children_pids * ", " }")
        children_pids.each do |pid|
          Log.medium("Killing child #{ pid }")
          begin
            Process.kill "INT", pid
          rescue Exception
            Log.medium("Exception killing child #{ pid }: #{$!.message}")
          end
        end
      end
    rescue
      Log.medium("Exception finding children")
    end
  end

  def run(no_load = false)
    result = nil

    begin
      @mutex.synchronize do
        no_load = :stream if no_load
        result = Persist.persist "Job", @task.result_type, :file => path, :check => checks, :no_load => no_load do 
          if Step === Step.log_relay_step and not self == Step.log_relay_step
            relay_log(Step.log_relay_step) unless self.respond_to? :relay_step and self.relay_step
          end

          @exec = false
          Open.write(pid_file, Process.pid.to_s)
          init_info

          log :setup, "#{Log.color :green, "Setup"} step #{Log.color :yellow, task.name.to_s || ""}"

          merge_info({
            :issued => (issue_time = Time.now),
            :name => name,
            :clean_name => clean_name,
          })

          set_info :dependencies, dependencies.collect{|dep| [dep.task_name, dep.name, dep.path]}

          begin
            run_dependencies
          rescue Exception
            FileUtils.rm pid_file if File.exist?(pid_file)
            stop_dependencies
            raise $!
          end

          set_info :inputs, Misc.remove_long_items(Misc.zip2hash(task.inputs, @inputs)) unless task.inputs.nil?

          set_info :started, (start_time = Time.now)
          log :started, "Starting step #{Log.color :yellow, task.name.to_s || ""}"

          begin
            result = _exec
          rescue Aborted, Interrupt
            log(:aborted, "Aborted")
            raise $!
          rescue Exception
            backtrace = $!.backtrace

            # HACK: This fixes an strange behaviour in 1.9.3 where some
            # backtrace strings are coded in ASCII-8BIT
            backtrace.each{|l| l.force_encoding("UTF-8")} if String.instance_methods.include? :force_encoding
            set_info :backtrace, backtrace 
            log(:error, "#{$!.class}: #{$!.message}")
            stop_dependencies
            raise $!
          end

          if not no_load or ENV["RBBT_NO_STREAM"] == "true" 
            result = prepare_result result, @task.description, info if IO === result 
            result = prepare_result result.stream, @task.description, info if TSV::Dumper === result 
          end

          stream = case result
                   when IO
                     result
                   when TSV::Dumper
                     result.stream
                   end

          if stream
            log :streaming, "Streaming step #{Log.color :yellow, task.name.to_s || ""}"

            callback = Proc.new do
              if AbortedStream === stream
                if stream.exception
                  raise stream.exception 
                else
                  raise Aborted
                end
              end
              begin
                if status != :done
                  Misc.insist do
                    set_info :done, (done_time = Time.now)
                    set_info :total_time_elapsed, (total_time_elapsed = done_time - issue_time)
                    set_info :time_elapsed, (time_elapsed = done_time - start_time)
                    log :done, "Completed step #{Log.color :yellow, task.name.to_s || ""} in #{time_elapsed.to_i}+#{(total_time_elapsed - time_elapsed).to_i} sec."
                  end
                end
              rescue
                Log.exception $!
              ensure
                Step.purge_stream_cache
                FileUtils.rm pid_file if File.exist?(pid_file)
              end
            end

            abort_callback = Proc.new do |exception|
              begin
                if exception
                  self.exception exception
                else
                  log :aborted, "#{Log.color :red, "Aborted"} step #{Log.color :yellow, task.name.to_s || ""}" if status == :streaming
                end
                _clean_finished
              rescue
                Log.exception $!
                stop_dependencies
                FileUtils.rm pid_file if File.exist?(pid_file)
              end
            end

            ConcurrentStream.setup stream, :callback => callback, :abort_callback => abort_callback

            if AbortedStream === stream 
              exception = stream.exception || Aborted
              self.exception exception
              _clean_finished
              raise exception
            end
          else
            set_info :done, (done_time = Time.now)
            set_info :total_time_elapsed, (total_time_elapsed = done_time - issue_time)
            set_info :time_elapsed, (time_elapsed = done_time - start_time)
            log :done, "Completed step #{Log.color :yellow, task.name.to_s || ""} in #{time_elapsed.to_i}+#{(total_time_elapsed - time_elapsed).to_i} sec."
            Step.purge_stream_cache
            FileUtils.rm pid_file if File.exist?(pid_file)
          end

          set_info :dependencies, dependencies.collect{|dep| [dep.task_name, dep.name, dep.path]}

          result
        end

        if no_load
          @result ||= result
          self
        else
          Step.purge_stream_cache
          @result = prepare_result result, @task.result_description
        end
      end
    rescue Aborted, Interrupt
      abort
      stop_dependencies
      raise $!
    rescue Exception
      exception $!
      stop_dependencies
      raise $!
    end
  end

  def produce(force=true)
    return self if done? and not dirty?

    if error? or aborted?
      if force or aborted? or recoverable_error?
        clean
      else
        raise "Error in job: #{status} - #{self.path}"
      end
    end

    clean if dirty? or (not running? and not done?)

    no_load = :stream
    run(false) unless started?

    join unless done?

    self
  end

  def fork(no_load = false, semaphore = nil)
    raise "Can not fork: Step is waiting for proces #{@pid} to finish" if not @pid.nil? and not Process.pid == @pid and Misc.pid_exists?(@pid) and not done? and info[:forked]
    sout, sin = Misc.pipe if no_load == :stream
    @pid = Process.fork do
      sout.close if sout
      Misc.pre_fork
      begin
        RbbtSemaphore.wait_semaphore(semaphore) if semaphore
        FileUtils.mkdir_p File.dirname(path) unless File.exist? File.dirname(path)
        begin
          @forked = true
          res = run no_load
          set_info :forked, true
          if sin
            io = TSV.get_stream res
            if io.respond_to? :setup
              io.setup(sin) 
              sin.pair = io
              io.pair = sin
            end
            begin
              Misc.consume_stream(io, false, sin)
            rescue 
              Log.warn "Could not consume stream (#{io.closed? ? 'closed' : 'open'}) into pipe for forked job: #{self.path}"
              Misc.consume_stream(io) unless io.closed?
            end
          end
        rescue Aborted, Interrupt
          Log.debug{"Forked process aborted: #{path}"}
          log :aborted, "Job aborted (#{Process.pid})"
          raise $!
        rescue Exception
          Log.debug("Exception '#{$!.message}' caught on forked process: #{path}")
          raise $!
        ensure
          join_stream
        end

        begin
          children_pids = info[:children_pids]
          if children_pids
            children_pids.each do |pid|
              if Misc.pid_exists? pid
                begin
                  Process.waitpid pid
                rescue Errno::ECHILD
                  Log.low "Waiting on #{ pid } failed: #{$!.message}"
                end
              end
            end
            set_info :children_done, Time.now
          end
        rescue Exception
          Log.debug("Exception waiting for children: #{$!.message}")
          RbbtSemaphore.post_semaphore(semaphore) if semaphore
          Kernel.exit! -1
        end
        set_info :pid, nil
      ensure
        RbbtSemaphore.post_semaphore(semaphore) if semaphore
        Kernel.exit! 0
      end
    end
    sin.close if sin
    @result = sout if sout 
    Process.detach(@pid)
    self
  end

  def abort_pid
    @pid ||= info[:pid]

    case @pid
    when nil
      Log.medium "Could not abort #{path}: no pid"
      false
    when Process.pid
      Log.medium "Could not abort #{path}: same process"
      false
    else
      Log.medium "Aborting pid #{path}: #{ @pid }"
      begin
        Process.kill("INT", @pid)
        Process.waitpid @pid
      rescue Exception
        Log.debug("Aborted job #{@pid} was not killed: #{$!.message}")
      end
      Log.medium "Aborted pid #{path}: #{ @pid }"
      true
    end
  end

  def abort_stream
    stream = @result if IO === @result
    @saved_stream = nil
    if stream and stream.respond_to? :abort and not stream.aborted?
      begin
        Log.medium "Aborting job stream #{stream.inspect} -- #{Log.color :blue, path}"
        stream.abort 
      rescue Aborted, Interrupt
        Log.medium "Aborting job stream #{stream.inspect} ABORTED RETRY -- #{Log.color :blue, path}"
        Log.exception $!
        retry
      end
    end
  end

  def _clean_finished
    if Open.exists? path and not status == :done
      Log.warn "Aborted job had finished. Removing result -- #{ path }"
      begin
        Open.rm path
      rescue Exception
        Log.warn "Exception removing result of aborted job: #{$!.message}"
      end
    end
  end

  def _abort
    return if @aborted
    @aborted = true
    Log.medium{"#{Log.color :red, "Aborting"} #{Log.color :blue, path}"}
    begin
      return if done?
      stop_dependencies
      abort_stream
      abort_pid if running?
    rescue Aborted, Interrupt
      Log.medium{"#{Log.color :red, "Aborting ABORTED RETRY"} #{Log.color :blue, path}"}
      retry
    rescue Exception
      Log.exception $!
      retry
    ensure
      _clean_finished
    end
  end

  def abort
    return if done? and status == :done
    _abort
    log(:aborted, "Job aborted") unless aborted? or error?
    self
  end

  def join_stream
    stream = get_stream if @result
    @result = nil
    if stream
      begin
        Misc.consume_stream stream 
        stream.join if stream.respond_to? :join
      rescue Exception
        stream.abort $!
        self._abort
      end
    end
  end

  def soft_grace
    until done? or File.exist?(info_file)
      sleep 1 
    end
    self
  end

  def grace
    until done? or result or error? or aborted? or streaming? 
      sleep 1 
    end
    self
  end

  def join

    grace

    if streaming?
      join_stream 
    end

    return self if not Open.exists? info_file

    return self if info[:joined]

    pid = @pid 

    Misc.insist [0.1, 0.2, 0.5, 1] do
      pid ||= info[:pid]
    end

    begin

      if pid.nil? or Process.pid == pid
        dependencies.each{|dep| dep.join }
      else
        begin
          Log.debug{"Waiting for pid: #{pid}"}
          Process.waitpid pid 
        rescue Errno::ECHILD
          Log.debug{"Process #{ pid } already finished: #{ path }"}
        end if Misc.pid_exists? pid
        pid = nil
        dependencies.each{|dep| dep.join }
      end

      sleep 1 until path.exists? or error? or aborted?

      self
    ensure
      set_info :joined, true
    end
  end
end
