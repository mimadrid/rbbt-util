require 'rbbt/util/log'
module Log
  class ProgressBar

    attr_accessor :depth, :num_reports, :desc, :io, :severity, :history

    # Creates a new instance. Max is the total number of iterations of the
    # loop. The depth represents how many other loops are above this one,
    # this information is used to find the place to print the progress
    # report.
    def initialize(max, options = {})
      options = Misc.add_defaults options, :depth => 0, :num_reports => 100, :desc => "Progress", :io => STDERR, :severity => Log.severity
      depth, num_reports, desc, io, severity = Misc.process_options options, :depth, :num_reports, :desc, :io, :severity

      @max = max
      @max = 1 if @max and @max < 1
      @current = 0
      @time = Time.now
      @last_report = -1
      @num_reports = num_reports
      @severity = severity
      @depth = depth
      @desc = desc
    end

    # Used to register a new completed loop iteration.
    def tick(step = nil)

      if step.nil?
        @current += 1
      else
        @current = step
      end

      if @max
        if percent - @last_report > 1.to_f/@num_reports.to_f 
          report
          @last_report=percent
        end
      else
        if @last_report == -1 or Time.now - @last_report >= 1.0 
          throughput
        end
      end

      nil
    end


    def progress
      @current.to_f/ @max
    end

    def percent
      (self.progress * 100).to_i
    end

    def eta
      (Time.now - @time)/progress * (1-progress)
    end

    def used
      (Time.now - @time).to_i
    end


    def up_lines(depth)
      "\033[#{depth + 1}F\033[2K"
    end

    def down_lines(depth)
      "\n\033[#{depth + 2}E"
    end

    def report_msg
      progress = self.progress
      percent = self.percent

      indicator = Log.color(:magenta, @desc) << " "
      10.times{|i|
        if i < progress * 10 then
          indicator << Log.color(:yellow, ".")
        else
          indicator << " "
        end
      }
      done = progress == 1

      used = self.used
      used = [used/3600, used/60 % 60, used % 60].map{|t|  "%02i" % t }.join(':')

      if progress == 1
        indicator << Log.color(:green, " done")
        indicator << Log.color(:blue, " #{used}")
      else
        indicator << " #{Log.color(:blue, percent.to_s << "%")}"

        eta = self.eta
        eta = [eta/3600, eta/60 % 60, eta % 60].map{|t| "%02i" % t }.join(':')

        indicator << " #{Log.color :yellow, used} used #{Log.color :yellow, eta} left"
      end

    end

    def thr
      @history ||= []
      @last_report = Time.now if @last_report == -1
      time = Time.now - @last_report
      thr = (@current / time).to_i

      @history << thr
      @history.shift if @history.length > 10

      thr
    end

    def mean
      @mean_max ||= 0
      if @history.length > 3
        mean = Misc.mean(@history[1..-1])
        @mean_max = mean if mean > @mean_max
      end
      mean
    end

    def throughput_msg
      thr = self.thr

      mean = self.mean

      indicator = Log.color(:magenta, @desc) 
      indicator << " #{ Log.color :blue, thr } per second"

      indicator << " -- #{ Log.color :yellow, mean.to_i } avg. #{ Log.color :yellow, @mean_max.to_i} max." if mean

      indicator
    end

    def print(io, str)
      LOG_MUTEX.synchronize do
        STDERR.print str
        Log.logfile.puts str unless Log.logfile.nil?
        Log::LAST.replace "progress"
      end
    end
    # Prints de progress report. It backs up as many lines as the meters
    # depth. Prints the progress as a line of dots, a percentage, time
    # spent, and time left. And then goes moves the cursor back to its
    # original line. Everything is printed to stderr.
    def report(io = STDERR)
      if Log::LAST != "progress"
        BARS.length.times{print(io, "\n")}
      end
      print(io, up_lines(@depth) << report_msg << down_lines(@depth)) if severity >= Log.severity
      @last_report = Time.now if @last_report == -1
    end

    def throughput(io = STDERR)
      if Log::LAST != "progress"
        BARS.length.times{print(io, "\n")}
      end
      print(io, up_lines(@depth) << throughput_msg << down_lines(@depth)) if severity >= Log.severity
      @last_report = Time.now
      @current = 0
    end
    BAR_MUTEX = Mutex.new
    BARS = []
    def self.new_bar(max, options = {})
      BAR_MUTEX.synchronize do
        options = Misc.add_defaults options, :depth => BARS.length
        BARS << (bar = ProgressBar.new(max, options))
        bar
      end
    end

    def self.remove_bar(bar)
      BAR_MUTEX.synchronize do
        index = BARS.index bar
        if index
          (index+1..BARS.length-1).each do |pos|
            bar = BARS[pos]
            bar.depth = pos - 1
            BARS[pos-1] = bar
          end 
          BARS.pop
        end
        Log::LAST.replace "removeprogress"
      end
    end

    def self.with_bar(max, options = {})
      bar = new_bar(max, options)
      begin
        yield bar
      ensure
        remove_bar(bar)
      end
    end
  end
end