require 'rbbt/persist'
require 'rbbt/persist/tsv'
require 'rbbt/util/log'
require 'rbbt/workflow/accessor'

class Step
  attr_accessor :path, :task, :inputs, :dependencies, :bindings
  attr_accessor :pid

  class Aborted < Exception; end

  def initialize(path, task = nil, inputs = nil, dependencies = nil, bindings = nil)
    @path = Path.setup(path)
    @task = task
    @bindings = bindings
    @dependencies = case
                    when dependencies.nil? 
                      []
                    when Array === dependencies
                      dependencies
                    else
                      [dependencies]
                    end
    @inputs = inputs || []
  end

  class << self
    attr_accessor :log_relay_step
  end

  def relay_log(step)
    return self unless Task === self.task and not self.task.name.nil?
    if not self.respond_to? :original_log
      class << self
        attr_accessor :relay_step
        alias original_log log 
        def log(status, message = nil, do_log = true)
          original_log(status, message, do_log)
          relay_step.log([task.name.to_s, status.to_s] * ">", message.nil? ? nil : [task.name.to_s, message] * ">", false)
        end
      end
    end
    @relay_step = step
    self
  end

  def prepare_result(value, description = nil, info = {})
    case
    when (not defined? Entity or description.nil? or not Entity.formats.include? description)
      value
    when (Annotated === value and info.empty?)
      value
    when Annotated === value
      annotations = value.annotations
      info.each do |k,v|
        value.send("#{h}=", v) if annotations.include? k
      end
      value
    else
      Entity.formats[description].setup(value, info.merge(:format => description))
    end
  end

  def exec
    result = @task.exec_in((bindings ? bindings : self), *@inputs)
    prepare_result result, @task.result_description
  end

  def join
    if @pid.nil?
      while not done? do
        sleep 5
      end
    else
      Log.debug "Waiting for pid: #{@pid}"
      begin
        Process.waitpid @pid
      rescue Errno::ECHILD
        Log.debug "Process #{ @pid } already finished: #{ path }"
      end
      @pid = nil
    end
    self
  end

  def run(no_load = false)
    result = Persist.persist "Job", @task.result_type, :file => @path, :check => rec_dependencies.collect{|dependency| dependency.path }.uniq, :no_load => no_load do
      if Step === Step.log_relay_step and not self == Step.log_relay_step
        relay_log(Step.log_relay_step) unless self.respond_to? :relay_step and self.relay_step
      end

      FileUtils.rm info_file if File.exists? info_file

      set_info :pid, Process.pid

      set_info :dependencies, dependencies.collect{|dep| [dep.task.name, dep.name]}
      dependencies.each{|dependency| 
        begin
          dependency.relay_log self
          dependency.run true
        rescue Exception
          backtrace = $!.backtrace
          set_info :backtrace, backtrace 
          log(:error, "Exception processing dependency #{dependency.path}")
          log(:error, "#{$!.class}: #{$!.message}")
          log(:error, "backtrace: #{$!.backtrace.first}")
          raise "Exception processing dependency #{dependency.path}"
        end
      }
      
      log(:started, "Starting task #{task.name || ""}")

      set_info :started, Time.now
      
      set_info :inputs, Misc.remove_long_items(Misc.zip2hash(task.inputs, @inputs)) unless task.inputs.nil?

      res = begin
              exec
            rescue Step::Aborted
              log(:error, "Aborted")

              children_pids = info[:children_pids]
              Log.medium("Killing children: #{ children_pids * ", " }")
              children_pids.each do |pid|
                Log.medium("Killing child #{ pid }")
                begin
                  Process.kill "INT", pid
                rescue Exception
                  Log.medium("Exception killing child #{ pid }: #{$!.message}")
                end
              end if children_pids

              raise $!
            rescue Exception
              backtrace = $!.backtrace

              # HACK: This fixes an strange behaviour in 1.9.3 where some
              # bactrace strings are coded in ASCII-8BIT
              backtrace.each{|l| l.force_encoding("UTF-8")} if String.instance_methods.include? :force_encoding

              set_info :backtrace, backtrace 
              log(:error, "#{$!.class}: #{$!.message}")
              log(:error, "backtrace: #{$!.backtrace.first}")
              raise $!
            end

      set_info :status, :done
      res
    end

    if no_load
      self
    else
      prepare_result result, @task.result_description, info
    end
  end

  def fork
    raise "Can not fork: Step is waiting for proces #{@pid} to finish" if not @pid.nil?
    @pid = Process.fork do
      trap(:INT) { raise Step::Aborted.new "INT signal recieved" }
      FileUtils.mkdir_p File.dirname(path) unless File.exists? File.dirname(path)
      begin
        run
        children_pids = info[:children_pids]
        if children_pids
          children_pids.each do |pid|
            begin
              Process.waitpid pid
            rescue Errno::ECHILD
              Log.debug "Child #{ pid } already finished: #{ path }"
            end
          end
        end
      rescue
        exit -1
      end
    end
    Process.detach(@pid)
    self
  end

  def abort
    @pid ||= info[:pid]
    if @pid.nil?
      Log.medium "Could not abort #{path}: no pid"
      false
    else
      Log.medium "Aborting #{path}: #{ @pid }"
      begin
        Process.kill("INT", @pid)
        Process.waitpid @pid
      rescue Exception
        Log.debug("Aborted job #{@pid} was not killed: #{$!.message}")
      end
      log(:aborted, "Job aborted by user")
      true
    end
  end

  def child(&block)
    child_pid = Process.fork &block
    children_pids = info[:children_pids]
    if children_pids.nil?
      children_pids = [child_pid]
    else
      children_pids << child_pid
    end
    Process.detach(child_pid)
    set_info :children_pids, children_pids
  end


  def load
    raise "Can not load: Step is waiting for proces #{@pid} to finish" if not done?
    result = Persist.persist "Job", @task.result_type, :file => @path, :check => rec_dependencies.collect{|dependency| dependency.path} do
      exec
    end
    prepare_result result, @task.result_description, info
  end

  def clean
    if File.exists?(path) or File.exists?(info_file)
      begin
        FileUtils.rm info_file if File.exists? info_file
        FileUtils.rm path if File.exists? path
        FileUtils.rm path + '.lock' if File.exists? path + '.lock'
        FileUtils.rm_rf files_dir if File.exists? files_dir
      end
    end
    self
  end

  def rec_dependencies
    @dependencies.collect{|step| step.rec_dependencies}.flatten.concat  @dependencies
  end

  def step(name)
    rec_dependencies.select{|step| step.task.name.to_sym == name.to_sym}.first
  end
end
