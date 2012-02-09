require 'rbbt/util/chain_methods'
require 'rbbt/util/misc'

module NamedArray
  extend ChainMethods

  self.chain_prefix = :named_array
  attr_accessor :fields
  attr_accessor :key
  attr_accessor :namespace

  def self.setup(array, fields, key = nil, namespace = nil)
    array.extend NamedArray unless NamedArray === array
    array.fields = fields
    array.key = key
    array.namespace = namespace
    array
  end

  def merge(array)
    double = Array === array.first 
    new = self.dup
    (0..length - 1).each do |i|
      if double
        new[i] = new[i] + array[i]
      else
        new[i] << array[i]
      end
    end
    new
  end

  def positions(fields)
    if Array ==  fields
      fields.collect{|field|
        Misc.field_position(@fields, field)
      }
    else
      Misc.field_position(@fields, fields)
    end
  end

  def named_array_get_brackets(key)
    pos = Misc.field_position(fields, key)
    elem = named_array_clean_get_brackets(pos)

    return elem if @fields.nil? or @fields.empty?

    field = NamedArray === @fields ? @fields.named_array_clean_get_brackets(pos) : @fields[pos]
    elem = Entity.formats[field].setup((elem.frozen? ? elem.dup : elem), (namespace ? {:namespace => namespace, :organism => namespace} : {}).merge({:format => field})) if defined?(Entity) and Entity.respond_to?(:formats) and Entity.formats.include?(field) and not field == elem
    elem
  end

  def named_array_each(&block)
    if defined?(Entity) and not @fields.nil? and not @fields.empty?
      @fields.zip(self).each do |field,elem|
        elem = Entity.formats[field].setup((elem.frozen? ? elem.dup : elem), (namespace ? {:namespace => namespace, :organism => namespace} : {}).merge({:format => field})) if defined?(Entity) and Entity.respond_to?(:formats) and Entity.formats.include?(field) and not field == elem
        yield(elem)
        elem
      end
    else
      named_array_clean_each &block
    end
  end

  def named_array_collect
    res = []

    named_array_each do |elem|
      if block_given?
        res << yield(elem)
      else
        res << elem
      end
    end

    res
  end

  def named_array_set_brackets(key,value)
    named_array_clean_set_brackets(Misc.field_position(fields, key), value)
  end

  def named_array_values_at(*keys)
    keys = keys.collect{|k| Misc.field_position(fields, k) }
    named_array_clean_values_at(*keys)
  end

  def zip_fields
    return [] if self.empty?
    zipped = Misc.zip_fields(self)
    zipped = zipped.collect{|v| NamedArray.setup(v, fields)}
    zipped 
  end

  def detach(file)
    file_fields = file.fields.collect{|field| field.fullname}
    detached_fields = []
    self.fields.each_with_index{|field,i| detached_fields << i if file_fields.include? field.fullname}
    fields = self.fields.values_at *detached_fields
    values = self.values_at *detached_fields
    values = NamedArray.name(values, fields)
    values.zip_fields
  end

  def report
    fields.zip(self).collect do |field,value|
      "#{ field }: #{ Array === value ? value * "|" : value }"
    end * "\n"
  end

end
