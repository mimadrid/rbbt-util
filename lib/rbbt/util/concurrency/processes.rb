require 'rbbt/util/concurrency/processes/worker'
require 'rbbt/util/concurrency/processes/socket'

class RbbtProcessQueue
  #{{{ RbbtProcessQueue

  attr_accessor :num_processes, :processes, :queue, :process_monitor, :cleanup
  def initialize(num_processes, cleanup = nil)
    @num_processes = num_processes
    @processes = []
    @cleanup = cleanup
    @queue = RbbtProcessSocket.new
  end

  attr_accessor :callback, :callback_queue, :callback_thread
  def callback(&block)
    if block_given?
      @callback = block

      @callback_queue = RbbtProcessSocket.new

      @callback_thread = Thread.new(Thread.current) do |parent|
        begin
          loop do
            p = @callback_queue.pop
            raise p if Exception === p
            raise p.first if Array === p and Exception === p.first
            @callback.call p
          end
        rescue Aborted
          Log.error "Callback thread aborted"
        rescue ClosedStream
        rescue Exception
          Log.error "Callback thread exception"
          parent.raise $!
        ensure
          @callback_queue.sread.close unless @callback_queue.sread.closed?
        end
      end
    else
      @callback, @callback_queue, @callback_thread = nil, nil, nil
    end
  end

  def init(&block)
    num_processes.times do |i|
      @processes << RbbtProcessQueueWorker.new(@queue, @callback_queue, @cleanup, &block)
    end
    @queue.close_read

    @process_monitor = Thread.new(Thread.current) do |parent|
      begin
        while @processes.any?
          @processes[0].join 
          @processes.shift
        end
      rescue Aborted
        @processes.each{|p| p.abort }
        Log.error "Process monitor aborted"
      rescue Exception
        Log.error "Process monitor exception: #{$!.message}"
        @processes.each{|p| p.abort }
        @callback_thread.raise $! if @callback_thread
        parent.raise $!
      end
    end
  end

  def close_callback
    begin
      @callback_queue.push ClosedStream.new if @callback_thread.alive?
    rescue
      Log.error "Error closing callback: #{$!.message}"
    end
    @callback_thread.join  if @callback_thread.alive?
  end

  def join
    @processes.length.times do 
      @queue.push ClosedStream.new
    end
    begin
      @process_monitor.join
      close_callback if @callback
    rescue Exception
      Log.exception $!
      raise $!
    ensure
      @queue.swrite.close
    end
  end

  def clean
    if @process_monitor.alive?
     @process_monitor.raise Aborted.new
     aborted = true
    end

    if @callback_thread and @callback_thread.alive?
     @callback_thread.raise Aborted.new
     aborted = true
    end
    raise Aborted.new if aborted
  end

  def abort
    @process_monitor.raise Aborted.new if @process_monitor and @process_monitor.alive?
    @callback_thread.raise Aborted.new if @callback_thread and @callback_thread.alive?
  end

  def process(*e)
    @queue.push e
  end

  def self.each(list, num = 3, &block)
    q = RbbtProcessQueue.new num
    q.init(&block)
    list.each do |elem| q.process elem end
    q.join
  end
end
