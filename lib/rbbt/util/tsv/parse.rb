require 'rbbt/util/misc'
class TSV
 
  def self.parse_fields(io, delimiter = "\t")
    return [] if io.nil?

    ## split with delimiter, do not remove empty
    fields = io.split(delimiter, -1)

    fields
  end

  def self.parse_header(stream, sep = nil, header_hash = nil)
    sep = /\t/ if sep.nil?
    header_hash = "#" if header_hash.nil?

    fields, key_field = nil
    options = {}

    # Get line

    line = stream.gets
    raise "Empty content" if line.nil?

    # Process options line
    
    if line and line =~ /^#{header_hash}: (.*)/
      options = Misc.string2hash $1
      line = stream.gets
    end

    # Determine separator
    
    sep = options[:sep] if options[:sep]

    # Process fields line

    if line and line =~ /^#{header_hash}/
      line.chomp!
      fields = parse_fields(line, sep)
      key_field = fields.shift
      key_field = key_field[(0 + header_hash.length)..-1] # Remove initial hash character
      line = stream.gets
    end

    # Return fields, options and first line

    return key_field, fields, options, line
  end

  def self.parse(stream, options = {})
    # Prepare options
    options = Misc.add_defaults options, 
      :case_insensitive => false,
      :type             => :double,
      :namespace        => nil,

      :merge            => false,
      :keep_empty       => true,
      :cast             => nil,

      :sep              => "\t",
      :sep2             => "|",
      :header_hash      => '#',

      :key              => 0,
      :fields           => nil,

      :fix              => nil,
      :exclude          => nil,
      :select           => nil,
      :grep             => nil


    sep, header_hash =
      Misc.process_options options, :sep,  :header_hash

    key_field, other_fields, more_options, line = TSV.parse_header(stream, sep, header_hash)

    sep     = more_options[:sep] if more_options[:sep]
    options = Misc.add_defaults options, more_options
    sep2    = Misc.process_options options, :sep2

    key, others =
      Misc.process_options options, :key, :others

    if key_field.nil?
      key_pos      = key
      key_field, fields = nil
    else
      all_fields = [key_field].concat other_fields

      key_pos   = Misc.field_position(all_fields, key)

      if String === others or Symbol === others
        others = [others]
      end

      if others.nil?
        other_pos    = (0..(all_fields.length - 1)).to_a
        other_pos.delete key_pos
      else
        other_pos = Misc.field_position(all_fields, *others)
      end

      key_field = all_fields[key_pos]
      fields    = all_fields.values_at *other_pos
    end

    case_insensitive, type, namespace, merge, keep_empty, cast = 
      Misc.process_options options, :case_insensitive, :type, :namespace, :merge, :keep_empty, :cast
    fix, exclude, select, grep = 
      Misc.process_options options, :fix, :exclude, :select, :grep 

    #{{{ Process rest
    data = {}
    single = type.to_sym != :double
    max_cols = 0
    while line do
      line.chomp!

      line = fix.call line if fix
      break if not line

      if header_hash and line =~ /^#{header_hash}/
        line = stream.gets
        next
      end

      if line.empty?                           or
         (exclude and     exclude.call(line))  or
         (select  and not select.call(line))

         line = stream.gets
         next
      end

      # Chunk fields
      parts = parse_fields(line, sep)

      # Get next line
      line = stream.gets

      # Get id field
      next if parts[key_pos].nil? || parts[key_pos].empty?
     
      if single
        ids = parse_fields(parts[key_pos], sep2)
        ids.collect!{|id| id.downcase} if case_insensitive
        
        id = ids.shift
        ids.each do |id2| data[id2] = "__Ref:#{id}"  end

        if key_field.nil?
          other_pos    = (0..(parts.length - 1)).to_a
          other_pos.delete key_pos
        end

        extra = parts.values_at(*other_pos).collect{|f| parse_fields(f, sep2).first}
        extra.collect! do |elem| 
          case
          when String === cast
            elem.send(cast)
          when Proc === cast
            cast.call elem
          end
        end if cast

        max_cols = extra.size if extra.size > (max_cols || 0)
        case type
        when :list
          data[id] = extra unless data.include? id
        when :flat
          data[id] = extra.flatten unless data.include? id  
        when :single
          data[id] = extra.flatten.first unless data.include? id  
        end
 
      else
        ids = parse_fields(parts[key_pos], sep2)
        ids.collect!{|id| id.downcase} if case_insensitive

        id = ids.shift
        ids.each do |id2| data[id2] = "__Ref:#{id}"  end

        if key_field.nil?
          other_pos    = (0..(parts.length - 1)).to_a
          other_pos.delete key_pos
        end

        extra = parts.values_at(*other_pos).collect{|f| parse_fields(f, sep2)}
        extra.collect! do |list| 
          case
          when String === cast
            list.collect{|elem| elem.send(cast)}
          when Proc === cast
            list.collect{|elem| cast.call elem}
          end
        end if cast

        max_cols = extra.size if extra.size > (max_cols || 0)
        if merge
          data[id] = extra unless data.include? id
        else
          if not data.include? id
            data[id] = extra
          else
            entry = data[id]
            while entry =~ /__Ref:(.*)/ do entry = data[$1] end
            extra.each_with_index do |f, i|
              if f.empty?
                next unless keep_empty
                f= [""]
              end
              entry[i] ||= []
              entry[i] = entry[i].concat f
            end
            data[id] = entry
          end
        end
      end
    end

    if keep_empty and max_cols > 0
      data.each do |key, values| 
        next if values =~ /__Ref:/
        new_values = values
        max_cols.times do |i|
          if type == :double
            new_values[i] = [""] if new_values[i].nil? or new_values[i].empty?
          else
            new_values[i] = "" if new_values[i].nil?
          end
        end
        data[key] = new_values
      end
    end

    [data, {:key_field => key_field, :fields => fields, :type => type, :case_insensitive => case_insensitive, :namespace => namespace}]
  end

end
