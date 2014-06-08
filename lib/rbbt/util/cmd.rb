require 'rbbt/util/log'
require 'stringio'

module CMD

  module SmartIO 
    attr_accessor :pid, :cmd, :post, :in, :out, :err, :log
    def self.tie(io, pid = nil, cmd = "",  post = nil, sin = nil, out = nil, err = nil, log = true)
      io.extend SmartIO
      io.pid = pid
      io.cmd = cmd
      io.in  = sin 
      io.out  = out 
      io.err  = err 
      io.post = post
      io.log = log

      io.class.send(:alias_method, :original_close, :close)
      io.class.send(:alias_method, :original_read, :read)
      io
    end

    def wait_and_status
      if @pid
        begin
          Process.waitpid(@pid)
        rescue
        end

        Log.debug{"Process #{ cmd } succeded" if $? and $?.success? and log}

        if $? and not $?.success?
          Log.debug{"Raising exception" if log}
          exception = ProcessFailed.new "Command [#{@pid}] '#{@cmd}' failed with error status #{$?.exitstatus}"
          begin
            original_close
          ensure
            raise exception
          end
        end
      end
    end

    def close
      self.original_read unless self.closed? or self.eof?

      wait_and_status

      @post.call if @post

      original_close unless self.closed?
    end

    def force_close
      if @pid
        Log.debug{"Forcing close by killing '#{@pid}'" if log}
        begin
          Process.kill("KILL", @pid)
          Process.waitpid(@pid)
        rescue
          Log.low{"Exception in forcing close of command [#{ @pid }, #{cmd}]: #{$!.message}"}
        end
      end

      @post.call if @post

      original_close unless self.closed?
    end

    def read(*args)
      data = original_read(*args) unless self.closed? #or self.eof?

      self.close if not self.closed? and self.eof?

      data #|| ""
    end
  end


  def self.process_cmd_options(options = {})
    string = ""
    options.each do |option, value|
      case 
      when value.nil? || FalseClass === value 
        next
      when TrueClass === value
        string << "#{option} "
      else
        if option.to_s.chars.to_a.last == "="
          string << "#{option}#{value} "
        else
          string << "#{option} #{value} "
        end
      end
    end

    string.strip
  end

  def self.cmd(cmd, options = {}, &block)
    options = Misc.add_defaults options, :stderr => Log::DEBUG
    in_content = options.delete(:in)
    stderr     = options.delete(:stderr)
    pipe       = options.delete(:pipe)
    post       = options.delete(:post)
    log        = options.delete(:log)
    dont_close_in        = options.delete(:dont_close_in)

    log = true if log.nil?

    if stderr == true
      stderr = Log::HIGH
    end

    # Process cmd_options
    cmd_options = process_cmd_options options
    if cmd =~ /'\{opt\}'/
      cmd.sub!('\'{opt}\'', cmd_options) 
    else
      cmd << " " << cmd_options
    end

    in_content = StringIO.new in_content if String === in_content

    sout, serr, sin = Misc.pipe, Misc.pipe, Misc.pipe

    pid = fork {
      begin
        sin.last.close
        sout.first.close
        serr.first.close

        io = in_content
        while IO === io
          if SmartIO === io
            io.original_close unless io.closed?
            io.out.close unless io.out.nil? or io.out.closed?
            io.err.close unless io.err.nil? or io.err.closed?
            io = io.in
          else
            io.close unless io.closed?
            io = nil
          end
        end

        STDIN.reopen sin.first
        sin.first.close

        STDERR.reopen serr.last
        serr.last.close

        STDOUT.reopen sout.last
        sout.last.close

        STDOUT.sync = STDERR.sync = true
        
        exec(ENV, cmd)

        exit(-1)
      rescue Exception
        Log.debug{ "ProcessFailed: #{$!.message}" } if log
        Log.debug{ "Backtrace: \n" + $!.backtrace * "\n" } if log
        raise ProcessFailed, $!.message
      end
    }

    sin.first.close
    sout.last.close
    serr.last.close

    sin = sin.last
    sout = sout.first
    serr = serr.first
    

    Log.debug{"CMD: [#{pid}] #{cmd}" if log}

    if in_content.respond_to?(:read)
      Thread.new do
        begin
          loop do
            break if in_content.closed?
            block = in_content.read 1024
            break if block.nil? or block.empty?
            sin.write block
          end

          sin.close unless sin.closed?
          in_content.join if in_content.respond_to? :join and not dont_close_in
          in_content.close unless in_content.closed? or dont_close_in
        rescue
          Process.kill "INT", pid
          raise $!
        end
      end
    else
      sin.close
    end

    if pipe
      Thread.new do
        while line = serr.gets
          Log.log line, stderr if Integer === stderr and log
        end
        serr.close
        Thread.exit!
      end

      #SmartIO.tie sout, pid, cmd, post, in_content, sin, serr
      ConcurrentStream.setup sout, :pids => [pid], :autojoin => true

      sout
    else
      err = ""
      Thread.new do
        while not serr.eof?
          err << serr.gets if Integer === stderr
        end
        serr.close
        Thread.exit
      end

      ConcurrentStream.setup sout, :pids => [pid], :autojoin => true
      out = StringIO.new sout.read
      sout.close unless sout.closed?

      Process.waitpid pid

      if not $?.success?
        raise ProcessFailed.new "Command [#{pid}] #{cmd} failed with error status #{$?.exitstatus}.\n#{err}"
      else
        Log.log err, stderr if Integer === stderr and log
      end

      out
    end
  end
end
