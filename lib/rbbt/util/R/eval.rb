require 'rbbt/util/R'
require 'rserve'

# Hack to make it work with local sockets
module Rserve
  module TCPSocket 
    def self.new(hostname, port_number)
      raise "Socket at #{hostname} not found" unless File.exists? hostname
      @s = Socket.unix hostname
    end
  end
end

module R
  SESSION = ENV["RServe-session"] || "Session-PID-" + Process.pid.to_s

  def self.socket_file
    @@socket_file ||= Rbbt.tmp.R_sockets[R::SESSION].find
  end

  def self.lockfile
    @@lockfile ||= socket_file + '.lock'
  end

  def self.workdir
    @@workdir ||= socket_file + '.wd'
  end

  def self.pid_file
    @@pidfile ||= File.join(workdir, 'pid')
  end

  def self.clear
    Log.warn "Clearing Rserver session #{SESSION}, PID #{@@instance_process}"
    @@instance = nil
    if defined? @@instance_process and @@instance_process and Misc.pid_exists? @@instance_process
      begin
        Process.kill :INT, @@instance_process
      rescue Exception
      end
    end
    FileUtils.rm_rf pid_file if File.exists? pid_file
    FileUtils.rm_rf socket_file if File.exists? socket_file
    FileUtils.rm_rf lockfile if File.exists? lockfile
    FileUtils.rm_rf workdir if File.exists? workdir
  end

  def self.instance
    @@instance ||= begin

                     clear if File.exists? pid_file and ! Misc.pid_exists?(Open.read(pid_file).strip.to_i)

                     FileUtils.mkdir_p File.dirname(socket_file) unless File.directory?(File.dirname(socket_file))
                     FileUtils.mkdir_p workdir unless File.directory? workdir

                     at_exit do
                       self.clear
                     end unless defined? @@instance_process

                     begin

                       if not File.exists? socket_file

                         sh_pid = Process.fork do
                           #args = %w(CMD Rserve --vanilla --quiet --RS-socket)
                           args = %w(--vanilla --quiet --RS-socket)
                           args << "'#{socket_file}'"
                           args << "--RS-workdir"
                           args << "'#{workdir}'"
                           args << "--RS-pidfile"
                           args << "'#{pid_file}'"

                           bin_path = File.join(ENV["R_HOME"], "bin/Rserve")
                           cmd = bin_path + " " + args*" "
                           exec(ENV, cmd)
                         end
                         while not File.exists? pid_file
                           sleep 0.5
                         end
                         @@instance_process = Open.read(pid_file).to_i
                         Log.info "New Rserver session stated with PID (#{sh_pid}) #{@@instance_process}: #{SESSION}"
                       end

                       i = Rserve::Connection.new :hostname => socket_file

                       begin
                        FileUtils.mkdir workdir unless File.exists? workdir
                        i.eval "setwd('#{workdir}');"
                        i.eval "source('#{UTIL}');" 
                        i
                       rescue Exception
                         Log.exception $!
                         raise TryAgain
                       end
                     rescue Exception
                       Log.exception $!
                       Process.kill :INT, @@instance_process if defined? @@instance_process and @@instance_process
                       FileUtils.rm socket_file if File.exists? socket_file
                       retry if TryAgain === $!
                       raise $!
                     end
                   end
  end

  def self._eval(cmd)
    Misc.lock lockfile do 
      times = 2
      begin
        instance.eval(cmd)
      rescue Rserve::Connection::EvalError
        times = times - 1
        if times > 0
          clear
          retry 
        else
          raise $!
        end
      end
    end
  end

  def self.eval_a(cmd)
    _eval(cmd).payload
  end

  def self.eval(cmd)
    eval_a(cmd).first
  end

  def self.eval_run(cmd)
    _eval(cmd)
  end

end
