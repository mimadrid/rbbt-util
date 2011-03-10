require 'rbbt/util/resource'
require 'rbbt/util/misc'
require 'rbbt/util/open'
require 'rbbt/util/tc_hash'
require 'rbbt/util/tmpfile'
require 'rbbt/util/log'
require 'rbbt/util/persistence'
require 'digest'
require 'fileutils'

require 'rbbt/util/tsv/parse'
require 'rbbt/util/tsv/accessor'
require 'rbbt/util/tsv/manipulate'
require 'rbbt/util/tsv/index'
require 'rbbt/util/tsv/attach'
require 'rbbt/util/tsv/resource'
class TSV

  def self.headers(file, options = {})

    ## Remove options from filename
    if String === file and file =~/(.*?)#(.*)/ and File.exists? $1
      options = Misc.add_defaults options, Misc.string2hash($2) 
      file = $1
    end

    fields = case
             when Open.can_open?(file)
               Open.open(file, :grep => options[:grep]) do |f| TSV.parse_header(f, options[:sep], options[:header_hash]).values_at(0, 1).flatten end
             when File === file
               file = Open.grep(file, options[:grep]) if options[:grep]
               TSV.parse_header(file, options[:sep], options[:header_hash]).values_at(0, 1).flatten
             else 
               raise "File #{file.inspect} not found"
             end

    if fields.compact.empty?
      nil
    else
      fields
    end
  end

  def self.encapsulate_persistence(file, options)
  end

  def initialize(file = {}, type = nil, options = {})
    # Process Options
    
    if Hash === type
      options = type 
      type    = nil
    end

    ## Remove options from filename
    if String === file and file =~/(.*?)#(.*)/ and File.exists? $1
      options = Misc.add_defaults options, Misc.string2hash($2) 
      file = $1
    end

    options = Misc.add_defaults options, :persistence => false, :type => type

    # Extract Filename

    file, extra  = file if Array === file and file.length == 2 and Hash === file.last

    @filename = Misc.process_options options, :filename
    @filename ||= case
                  when Resource::Path === file
                    file
                  when (String === file and File.exists? file)
                    File.expand_path file
                  when String === file
                    file
                  when File === file
                    File.expand_path file.path
                  when TSV === file 
                    File.expand_path file.filename
                  when (Persistence::TSV === file and file.filename)
                    File.expand_path file.filename
                  else
                    file.class.to_s
                  end

    # Process With Persistence
    #     Use filename to identify the persistence
    #     Several inputs supported
    #         Filename or File: Parsed
    #         Hash: Encapsulated, empty info
    #         TSV: Duplicate
    case
    when block_given?
      @data, extra = Persistence.persist(file, :TSV, :tsv_extra, options.merge(:force_array => true)) do |file, options, filename| yield file, options, filename end
      extra.each do |key, values|
        self.send("#{ key }=".to_sym, values) if self.respond_to? "#{ key }=".to_sym 
      end if not extra.nil?
 
    else
      case
      when Array === file
        @data = Hash[file.collect{|v| 
          [v,[]]
        }]
      when Hash === file 
        @data = file
      when TSV === file
        @data = file.data
      when Persistence::TSV === file
        @data = file
        %w(case_insensitive namespace identifiers datadir fields key_field type filename cast).each do |key|
          if @data.respond_to?(key.to_sym)  and self.respond_to?("#{key}=".to_sym)
            self.send "#{key}=".to_sym, @data.send(key.to_sym) 
          end
        end
      else
        @data, extra = Persistence.persist(file, :TSV, :tsv_extra, options) do |file, options, filename|
          data, extra = nil

          case
            ## Parse source
          when Resource::Path === file #(String === file and file.respond_to? :open)
            data, extra = TSV.parse(file.open(:grep => options[:grep]) , options)
            extra[:namespace] ||= file.namespace
            extra[:datadir]   ||= file.datadir
          when StringIO === file
            data, extra = TSV.parse(file, options)
          when Open.can_open?(file)
            Open.open(file, :grep => options[:grep]) do |f|
              data, extra = TSV.parse(f, options)
            end
          when File === file
            path = file.path
            file = Open.grep(file, options[:grep]) if options[:grep]
            data, extra = TSV.parse(file, options)
          when IO === file
            file = Open.grep(file, options[:grep]) if options[:grep]
            data, extra = TSV.parse(file, options)
          when block_given?
            data 
          else
            raise "Unknown input in TSV.new #{file.inspect}"
          end

          extra[:filename] = filename

          [data, extra]
        end
      end
    end

    if not extra.nil?
      %w(case_insensitive namespace identifiers datadir fields key_field type filename cast).each do |key| 
        if extra.include? key.to_sym
          self.send("#{key}=".to_sym, extra[key.to_sym])
          if @data.respond_to? "#{key}=".to_sym
            @data.send("#{key}=".to_sym, extra[key.to_sym])
          end
        end
      end 
    end
  end

  def write
    @data.write if @data.respond_to? :write
  end

  def read
    @data.read if @data.respond_to? :read
  end

end
