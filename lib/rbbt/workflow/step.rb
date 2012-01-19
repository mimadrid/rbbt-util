require 'rbbt/persist'
require 'rbbt/persist/tsv'
require 'rbbt/util/log'
require 'rbbt/workflow/accessor'

class Step
  attr_accessor :path, :task, :inputs, :dependencies, :bindings
  attr_accessor :pid

  class Aborted < Exception; end

  def initialize(path, task = nil, inputs = nil, dependencies = nil, bindings = nil)
    @path = path
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

  def prepare_result(value, description = nil, info = {})
    return value if description.nil?
    Entity.formats[description].setup(value, info.merge(:format => description)) if defined?(Entity) and Entity.respond_to?(:formats) and Entity.formats.include? description
    value
  end

  def exec
    result = @task.exec_in((bindings ? bindings : self), *@inputs)
    prepare_result result, @task.result_description
  end

  def join
    if @pid.nil?
      while not done? do
        Log.debug "Waiting: #{info[:step]}"
        sleep 5
      end
    else
      Log.debug "Waiting for pid: #{@pid}"
      Process.waitpid @pid
      @pid = nil
    end
    self
  end

  def run(no_load = false)
    result = Persist.persist "Job", @task.result_type, :file => @path, :check => rec_dependencies.collect{|dependency| dependency.path}.uniq, :no_load => no_load do
      log :starting, "Starting task: #{ name }"
      set_info :dependencies, @dependencies.collect{|dep| [dep.task.name, dep.name]}
      @dependencies.each{|dependency| dependency.run true}
      set_info :status, :started
      set_info :inputs, Misc.zip2hash(task.inputs, @inputs) unless task.inputs.nil?
      res = exec
      set_info :status, :done
      res
    end

    prepare_result result, @task.result_description, info
  end

  def fork
    raise "Can not fork: Step is waiting for proces #{@pid} to finish" if not @pid.nil?
    @pid = Process.fork do
      begin
        trap(:INT) { raise Step::Aborted.new "INT signal recieved" }
        FileUtils.mkdir_p File.dirname(path)
        File.open(path + '.log', 'w') do |file|
          Log.logfile = file
          run
        end
      rescue Exception
        set_info :backtrace, $!.backtrace
        log(:error, "#{$!.class}: #{$!.message}")
      end
    end
    set_info :pid, @pid
    self
  end

  def abort
    if @pid.nil?
      false
    else
      Process.kill("INT", @pid)
      true
    end
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
