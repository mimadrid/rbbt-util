module SOPT

  #{{{ ACCESSORS
  
  class << self
    attr_accessor :command, :summary, :synopsys, :description
    attr_accessor :inputs, :input_shortcuts, :input_types, :input_descriptions, :input_defaults
  end

  def self.command
    @command ||= File.basename($0)
  end

  def self.summary
    @summary ||= ""
  end

  def self.synopsys
    @synopsys ||= begin
                    "#{command} " <<
                    inputs.collect{|name|
                      "[" << input_format(name, input_types[name] || :string, input_defaults[name], input_shortcuts[name]).sub(/:$/,'') << "]"
                    } * " "
                  end
  end

  def self.description
    @description ||= "Missing"
  end

  def self.shortcuts
    @shortcuts ||= []
  end

  def self.delete_inputs(inputs)
    inputs.each do |input|
      input = input.to_s
      self.shortcuts.delete self.input_shortcuts.delete(input)
      self.inputs.delete input
      self.input_types.delete input
      self.input_defaults.delete input
      self.input_descriptions.delete input
    end
  end

  def self.all
    @all ||= {}
  end
  
  def self.inputs 
    @inputs ||= []
  end

  def self.input_shortcuts 
    @input_shortcuts ||= {}
  end

  def self.input_types 
    @input_types ||= {}
  end

  def self.input_descriptions 
    @input_descriptions ||= {}
  end

  def self.input_defaults 
    @input_defaults ||= {}
  end

  def self.reset
    @shortcuts = []
    @all = {}
  end

  #{{{ PARSING
  
  def self.record(info)
    input = info[:long].sub("--", '')
    inputs << input
    input_types[input] = info[:arg] ? :string : :boolean
    input_descriptions[input] = info[:description]
    input_defaults[input] = info[:default]
    input_shortcuts[input] = info[:short]? info[:short].sub("-",'') : nil
  end

  def self.short_for(name)
    short = []
    chars = name.to_s.chars.to_a

    short << chars.shift 
    shortcuts = input_shortcuts.values.compact.flatten
    while shortcuts.include? short * "" and chars.any?
      short << chars.shift 
    end
    return nil if chars.empty?

    short * ""
  end


  def self.name(info)
    (info[:long] || info[:short]).sub(/^-*/,'')
  end

  def self.parse(opts)
    info = {}

    opts.split(/[:\n]+/).each do |opt|
      next if opt.strip.empty?

      short, long = opt.strip.sub(/(^[^\s]*)\*/,'\1').split('--').values_at(0,1)
      long, short = short, nil if long.nil?

      if long.index(" ")
        long, description = long.match(/^([^\s]+)\s+(.*)/).values_at 1, 2
      else
        description = nil
      end
      
      i= { :arg => !!opt.match(/^[^\s]*\*/) }

      i[:short]       = short unless short.nil? || short.empty?
      i[:long]        = '--' + long unless long.nil? || long.empty?
      i[:description] = description unless description.nil? || description.empty?

      if shortcuts.include? short
        i[:short] = short_for(i[:long])
        Log.debug{ "Short for #{ long } is taken. Changed to #{i[:short]}" }
      else
        shortcuts << i[:short] if short
      end

      record(i)

      info[name(i)] = i
    end

    info
  end

  def self.get(opts)
    info = parse(opts)

    switches = {}
    info.each do |name, i|
      switches[i[:short]] = name if i[:short]
      switches[i[:long]] = name if i[:long]
    end

    options = Hash.new(false)
    rest = []

    index = 0
    while index < ARGV.length do
      orig_arg = ARGV[index]

      if orig_arg =~ /=/
        arg, value = orig_arg.match(/(.*?)=(.*)/).values_at 1, 2
      else
        arg = orig_arg
        value = nil
      end

      if switches.include? arg
        name = switches[arg]
        i = info[name]
        if i[:arg]
          if value.nil?
            value = ARGV[index + 1]
            index += 1
          end
          options[name.to_sym] = value
        else
          options[name.to_sym] = value == "false" ? false : true
        end
      else
        rest << orig_arg
      end
      index += 1
    end

    ARGV.delete_if do true end
    rest.each do |e| ARGV << e end

    options
  end

  #{{{ DOCUMENTATION

  def self.input_format(name, type = nil, default = nil, short = "")
    short = short_for(name) if not short.nil? and short.empty?

    input_str = short.nil? ? "--#{name}" : "-#{short}, --#{name}"
    input_str << case type
    when nil
      "#{default != nil ? " (default '#{default}')" : ""}:"
    when :boolean
      "[=false]#{default != nil ? " (default '#{default}')" : ""}:"
    when :tsv, :text
      "=<filename.#{type}|->#{default != nil ? " (default '#{default}')" : ""}; Use '-' for STDIN:"
    when :array
      "=<string[,string]*|filename.list|->#{default != nil ? " (default '#{default}')" : ""}; Use '-' for STDIN:"
    else
      "=<#{ type }>#{default != nil ? " (default '#{default}')" : ""}:"
    end
  end

  def self.input_doc(inputs, input_types = nil, input_descriptions = nil, input_defaults = nil, input_shortcuts = nil)
    type = description = default = nil
    shortcut = ""
    inputs.collect do |name|

      type = input_types[name] unless input_types.nil?
      description = input_descriptions[name] unless input_descriptions.nil?
      default = input_defaults[name] unless input_defaults.nil?
      shortcut = input_shortcuts[name] unless input_shortcuts.nil?

      type = :string if type.nil?

      str  = "  * " << SOPT.input_format(name, type.to_sym, default, shortcut) << "\n"
      str << "    " << description << "\n" if description and not description.empty?
      str
    end * "\n"
  end

  def self.doc
    doc = <<-EOF
#{command}(1) -- #{summary}
#{"=" * (command.length + summary.length + 7)}

## SYNOPSYS

#{synopsys}

## DESCRIPTION

#{description}

## OPTIONS

#{input_doc(inputs, input_types, input_descriptions, input_defaults, input_shortcuts)}
    EOF
  end
end
