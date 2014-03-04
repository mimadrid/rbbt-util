class RbbtThreadQueue
  attr_accessor :num_threads, :threads, :queue, :mutex, :block, :done

  class RbbtThreadQueueWorker < Thread
    def initialize(queue, mutex = nil, &block)
      if mutex.nil?
        super(Thread.current) do |current|
          begin
            loop do
              p = queue.pop
              block.call *p
            end
          rescue Exception
            current.raise $! unless Aborted === $!
          end
        end
      else
        super(Thread.current) do |current|
          begin
            loop do
              p = queue.pop
              p << mutex 
              block.call *p
            end
          rescue Exception
            current.raise $! unless Aborted === $!
          end
        end
      end
    end

    def clean
      raise Aborted if alive?
    end
  end

  def initialize(num_threads)
    @num_threads = num_threads
    @threads = []
    @queue = Queue.new
    @mutex = Mutex.new
  end

  def init(use_mutex = false, &block)
    clean
    num_threads.times do |i|
      @threads << RbbtThreadQueueWorker.new(queue, use_mutex ? mutex : nil, &block)
    end
  end

  def join
    while queue.length > 0 or queue.num_waiting < @threads.length
      Thread.pass 
      raise "No worker thread survived" if @threads.empty? and queue.length > 0
    end
    @threads.delete_if{|t| t.alive?}
    @threads.each{|t| t.raise Aborted } 
    @threads.each{|t| t.join(0.1) } 
  end

  def clean
    threads.each{ |t| t.clean }.clear
  end

  def process(e)
    queue << e
  end
end
