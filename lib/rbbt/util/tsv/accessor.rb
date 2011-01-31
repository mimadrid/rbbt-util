require 'rbbt/util/misc'

class TSV
  ## Make sure we overwrite the methods declared by attr_accessor
  attr_accessor :filename, :type, :case_insensitive, :key_field, :fields, :data

  module Field
    def ==(string)
      return false unless String === string
      self.sub(/#.*/,'').casecmp(string.sub(/#.*/,'')) == 0
    end
  end

  def fields
    return nil if @fields.nil?
    fields = @fields
    fields.each do |f| f.extend Field end if Array === fields
    fields
  end

  def self.identify_field(key, fields, field)
    return field if Integer === field
    return nil if fields.nil?
    return :key if field.nil? or field == 0 or field.to_sym == :key or key == field
    return fields.index field
  end

  def identify_field(field)
    TSV.identify_field(key_field, fields, field)
  end


  def fields=(new_fields)
    @fields = new_fields
    @data.fields = new_fields if @data.respond_to? :fields=
  end

  def keys
    @data.keys
  end

  def values
    @data.values
  end

  def size
    @data.size
  end

  # Write

  def []=(key, value)
    key = key.downcase if @case_insensitive
    @data[key] = value
  end


  def merge!(new_data)
    new_data.each do |key, value|
      self[key] = value
    end
  end

  # Read

  def follow(value)
    return nil if value.nil?
    if String === value && value =~ /__Ref:(.*)/
      return self[$1]
    else
      value = NamedArray.name value, fields if Array === value and fields 
      value
    end
  end

  def [](key)
    if Array === key
      return @data[key] if @data[key] != nil
      key.each{|k| v = self[k]; return v unless v.nil?}
      return nil
    end

    key = key.downcase if @case_insensitive and key !~ /^__Ref:/
    follow @data[key]
  end

  def values_at(*keys)
    keys.collect{|k|
      self[k]
    }
  end

  def each(&block)
    @data.each do |key, value|
      block.call(key, follow(value))
    end
  end

  def collect
    if block_given?
      @data.collect do |key, value|
        value = follow(value)
        key, values = yield key, value
      end
    else
      @data.collect do |key, value|
        [key, follow(value)]
      end
    end
  end

  def sort(&block)
    collect.sort(&block).collect{|p|
      key, value = p
      value = NamedArray.name value, fields if fields
      [key, value]
    }
  end

  def sort_by(&block)
    collect.sort_by &block
  end

  def values_to_s(values)
      case
      when (values.nil? and fields.nil?)
        "\n"
      when (values.nil? and not fields.nil?)
        "\t" << ([""] * fields.length) * "\t" << "\n"
      when (not Array === values)
        "\t" << values.to_s << "\n"
      when Array === values.first
        "\t" << values.collect{|list| (list || []) * "|"} * "\t" << "\n"
      else
        "\t" << values * "\t" << "\n"
      end
  end

  def to_s(keys = nil)
    str = ""

    if fields
      str << "#" << key_field << "\t" << fields * "\t" << "\n"
    end

    if keys.nil?
      each do |key, values|
        key = key.to_s if Symbol === key
        str << key.dup << values_to_s(values)
      end
    else
      keys.zip(values_at(*keys)).each do |key, values|
        key = key.to_s if Symbol === key
        str << key.dup << values_to_s(values)
      end
    end

    str
  end

end
