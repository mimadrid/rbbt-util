class FixWidthTable

  attr_accessor :filename, :file, :value_size, :record_size, :range, :size, :mask, :write
  def initialize(filename, value_size = nil, range = nil, update = false, in_memory = true)
    @filename = filename

    if update or %w(memory stringio).include?(filename.to_s.downcase) or not File.exist?(filename)
      Log.debug "FixWidthTable create: #{ filename }"
      @value_size  = value_size
      @range       = range
      @record_size = @value_size + (@range ? 16 : 8)
      @write = true

      if %w(memory stringio).include? filename.to_s.downcase
        @filename = :memory
        @file     = StringIO.new
      else
        FileUtils.rm @filename if File.exist? @filename
        FileUtils.mkdir_p File.dirname(@filename) unless File.exist? @filename
        @file = File.open(@filename, 'wb')
      end

      @file.write [value_size].pack("L")
      @file.write [@range ? 1 : 0 ].pack("C")

      @size = 0
    else
      Log.debug "FixWidthTable up-to-date: #{ filename }"
      if in_memory
        @file        = StringIO.new(Open.read(@filename, :mode => 'r:ASCII-8BIT'), 'r')
      else
        @file        = File.open(@filename, 'r:ASCII-8BIT')
      end
      @value_size  = @file.read(4).unpack("L").first
      @range       = @file.read(1).unpack("C").first == 1
      @record_size = @value_size + (@range ? 16 : 8)
      @write = false

      @size        = (File.size(@filename) - 5) / (@record_size)
    end

    @mask = "a#{@value_size}"
  end

  def write?
    @write
  end

  def persistence_path
    @filename
  end

  def persistence_path=(value)
    @filename=value
  end

  def self.get(filename, value_size = nil, range = nil, update = false)
    return self.new(filename, value_size, range, update) if filename == :memory
    case
    when (!File.exist?(filename) or update or not Persist::CONNECTIONS.include?(filename))
      Persist::CONNECTIONS[filename] = self.new(filename, value_size, range, update)
    end

    Persist::CONNECTIONS[filename] 
  end

  def format(pos, value)
    padding = value_size - value.length
    if range
      (pos  + [padding, value + ("\0" * padding)]).pack("llll#{mask}")
    else
      [pos, padding, value + ("\0" * padding)].pack("ll#{mask}")
    end
  end

  def add(pos, value)
    format = format(pos, value)
    @file.write format

    @size += 1
  end

  def last_pos
    pos(size - 1)
  end

  def pos(index)
    return nil if index < 0 or index >= size
    @file.seek(5 + (record_size) * index, IO::SEEK_SET)
    @file.read(4).unpack("l").first
  end

  def pos_end(index)
    return nil if index < 0 or index >= size
    @file.seek(9 + (record_size) * index, IO::SEEK_SET)
    @file.read(4).unpack("l").first
  end

  def overlap(index)
    return nil if index < 0 or index >= size
    @file.seek(13 + (record_size) * index, IO::SEEK_SET)
    @file.read(4).unpack("l").first
  end

  def value(index)
    return nil if index < 0 or index >= size
    @file.seek((range ? 17 : 9 ) + (record_size) * index, IO::SEEK_SET)
    padding = @file.read(4).unpack("l").first+1
    txt = @file.read(value_size)
    str = txt.unpack(mask).first
    padding > 1 ? str[0..-padding] : str
  end

  def read(force = false)
    return if @filename == :memory
    @write = false
    @file.close unless @file.closed?
    @file = File.open(filename, 'r:ASCII-8BIT')
  end

  def close
    @write = false
    @file.close
  end

  def dump
    read
    @file.rewind
    @file.read
  end

  #{{{ Adding data

  def add_point(data)
    data.sort_by{|value, pos| pos }.each do |value, pos|
      add pos, value
    end
  end

  def add_range_point(pos, value)
    @latest ||= []
    while @latest.any? and @latest[0] < pos[0]
      @latest.shift
    end
    overlap = @latest.length
    add pos + [overlap], value
    @latest << pos[1]
  end

  def add_range(data)
    @latest = []
    data.sort_by{|value, pos| pos[0] }.each do |value, pos|
      add_range_point(pos, value)
    end
  end

  #{{{ Searching

  def closest(pos)
    upper = size - 1
    lower = 0

    return -1 if upper < lower

    while(upper >= lower) do
      idx = lower + (upper - lower) / 2
      pos_idx = pos(idx)

      case pos <=> pos_idx
      when 0
        break
      when -1
        upper = idx - 1
      when 1
        lower = idx + 1
      end
    end

    if pos_idx > pos
      idx = idx - 1
    end

    idx.to_i
  end

  def get_range(pos)
    case pos
    when Range
      r_start = pos.begin
      r_end   = pos.end
    when Array
      r_start, r_end = pos
    else
      r_start, r_end = pos, pos
    end

    idx = closest(r_start)

    return [] if idx >= size
    return [] if idx <0 and r_start == r_end

    idx = 0 if idx < 0

    overlap = overlap(idx)

    idx -= overlap unless overlap.nil?

    values = []
    l_start = pos(idx)
    l_end   = pos_end(idx)
    while l_start <= r_end
      values << value(idx) if l_end >= r_start 
      idx += 1
      break if idx >= size
      l_start = pos(idx)
      l_end   = pos_end(idx)
    end

    values
  end

  def get_point(pos)
    if Range === pos
      r_start = pos.begin
      r_end   = pos.end
    else
      r_start = pos.to_i
      r_end   = pos.to_i
    end

    idx = closest(r_start)

    return [] if idx >= size
    return [] if idx <0 and r_start == r_end

    idx = 0 if idx < 0

    idx += 1 unless pos(idx) >= r_start

    return [] if idx >= size

    values = []
    l_start = pos(idx)
    l_end   = pos_end(idx)
    while l_start <= r_end
      values << value(idx)
      idx += 1
      break if idx >= size
      l_start = pos(idx)
      l_end   = pos_end(idx)
    end

    values
  end

  def [](pos)
    return [] if size == 0
    if range
      get_range(pos)
    else
      get_point(pos)
    end
  end


  def values_at(*list)
    list.collect{|pos|
      self[pos]
    }
  end

  def chunked_values_at(keys, max = 5000)
    Misc.ordered_divide(keys, max).inject([]) do |acc,c|
      new = self.values_at(*c)
      new.annotate acc if new.respond_to? :annotate and acc.empty?
      acc.concat(new)
    end
  end
end
