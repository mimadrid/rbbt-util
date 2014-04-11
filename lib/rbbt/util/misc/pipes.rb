module Misc

  PIPE_MUTEX = Mutex.new

  OPEN_PIPE_IN = []
  def self.pipe
    OPEN_PIPE_IN.delete_if{|pipe| pipe.closed? }
    PIPE_MUTEX.synchronize do
      sout, sin = IO.pipe
      OPEN_PIPE_IN << sin

      [sout, sin]
    end
  end
  
  def self.release_pipes(*pipes)
    PIPE_MUTEX.synchronize do
      pipes.flatten.each do |pipe|
        pipe.close unless pipe.closed?
      end
    end
  end


  def self.purge_pipes(*save)
    PIPE_MUTEX.synchronize do
      OPEN_PIPE_IN.each do |pipe|
        next if save.include? pipe
        pipe.close unless pipe.closed?
      end
    end
  end

  def self.open_pipe(do_fork = false, close = true)
    raise "No block given" unless block_given?

    sout, sin = Misc.pipe

    if do_fork
      parent_pid = Process.pid
      pid = Process.fork {
        purge_pipes(sin)
        sout.close
        begin
          yield sin
        rescue
          Log.exception $!
          Process.kill :INT, parent_pid
          Kernel.exit! -1
        ensure
          sin.close if close and not sin.closed? 
        end
        Kernel.exit! 0
      }
      sin.close #if close
      ConcurrentStream.setup sout, :pids => [pid]
    else
      thread = Thread.new(Thread.current) do |parent|
        begin
          yield sin
        rescue
          parent.raise $!
        ensure
          sin.close if close and not sin.closed?
        end
      end
      ConcurrentStream.setup sout, :threads => [thread]
    end
    sout
  end

  def self.tee_stream_fork(stream)
    stream_out1, stream_in1 = Misc.pipe
    stream_out2, stream_in2 = Misc.pipe

    splitter_pid = Process.fork do
      Misc.purge_pipes(stream_in1, stream_in2)
      stream_out1.close
      stream_out2.close
      begin
        filename = stream.respond_to?(:filename)? stream.filename : nil
        skip1 = skip2 = false
        while block = stream.read(2048)
          begin stream_in1.write block; rescue Exception;  Log.exception $!; skip1 = true end unless skip1 
          begin stream_in2.write block; rescue Exception;  Log.exception $!; skip2 = true end unless skip2 
        end
        raise "Error writing in stream_in2" if skip2
        raise "Error writing in stream_in2" if skip2
      rescue Aborted
        stream.abort if stream.respond_to? :abort
        raise $!
      rescue IOError
        Log.exception $!
      rescue Exception
        Log.exception $!
      ensure
        stream_in1.close 
        stream_in2.close 
        stream.join if stream.respond_to? :join
      end
    end
    stream.close
    stream_in1.close
    stream_in2.close
    #stream.join if stream.respond_to? :join

    ConcurrentStream.setup stream_out1, :pids => [splitter_pid]
    ConcurrentStream.setup stream_out2, :pids => [splitter_pid]

    [stream_out1, stream_out2]
  end

  def self.tee_stream_thread(stream)
    stream_out1, stream_in1 = Misc.pipe
    stream_out2, stream_in2 = Misc.pipe

    splitter_thread = Thread.new(Thread.current, stream_in1, stream_in2) do |parent,stream_in1,stream_in2|
      begin
        filename = stream.respond_to?(:filename)? stream.filename : nil
        skip1 = skip2 = false
        while block = stream.read(2048)
          begin stream_in1.write block; rescue Exception; Aborted === $! ? raise($!): Log.exception($!); skip1 = true end unless skip1 
          begin stream_in2.write block; rescue Exception; Aborted === $! ? raise($!): Log.exception($!); skip2 = true end unless skip2 
        end
      rescue Aborted
        stream.abort if stream.respond_to? :abort
        raise $!
      rescue IOError
        Log.exception $!
      rescue Exception
        Log.exception $!
        parent.raise $!
      ensure
        stream_in1.close 
        stream_in2.close 
        stream.join if stream.respond_to? :join
      end
    end

    ConcurrentStream.setup stream_out1, :threads => splitter_thread
    ConcurrentStream.setup stream_out2, :threads => splitter_thread

    [stream_out1, stream_out2]
  end

  class << self
    alias tee_stream tee_stream_thread 
  end

  def self.read_full_stream(io)
    str = ""
    begin
      while block = io.read(2048)
        str << block
      end
    rescue
      io.abort if io.respond_to? :abort
    ensure
      io.join if io.respond_to? :join
      io.close if io.respond_to? :close
    end
    str
  end

  def self.consume_stream(io)
    begin
      while block = io.read(2048)
        return if io.eof?
        Thread.pass 
     end
    rescue
      io.abort if io.respond_to? :abort
    ensure
      io.join if io.respond_to? :join
      io.close if io.respond_to? :close
    end
  end

  def self.read_stream(stream, size)
    str = nil
    Thread.pass while IO.select([stream],nil,nil,1).nil?
    while not str = stream.read(size)
      IO.select([stream],nil,nil,1) 
      Thread.pass
      raise ClosedStream if stream.eof?
    end

    while str.length < size
      raise ClosedStream if stream.eof?
      IO.select([stream],nil,nil,1)
      if new = stream.read(size-str.length)
        str << new
      end
    end
    str
  end

  def self.read_stream(stream, size)
    str = nil
    Thread.pass while IO.select([stream],nil,nil,1).nil?
    while not str = stream.read(size)
      IO.select([stream],nil,nil,1) 
      Thread.pass
      raise ClosedStream if stream.eof?
    end

    while str.length < size
      raise ClosedStream if stream.eof?
      IO.select([stream],nil,nil,1)
      if new = stream.read(size-str.length)
        str << new
      end
    end
    str
  end
  def self._read_stream(stream, size)
    str = ""
    while (len=str.length) < size
      str << (stream.read(size-len) or break)
    end
    str
  end

end
