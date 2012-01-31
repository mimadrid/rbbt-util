require 'tokyocabinet'

module Persist
  TC_CONNECTIONS = {}

  def self.open_tokyocabinet(path, write, serializer = nil, tokyocabinet_class = TokyoCabinet::HDB)
    write = true if not File.exists?(path)

    tokyocabinet_class = TokyoCabinet::HDB if tokyocabinet_class == "HDB"
    tokyocabinet_class = TokyoCabinet::BDB if tokyocabinet_class == "BDB"

    flags = (write ? tokyocabinet_class::OWRITER | tokyocabinet_class::OCREAT : tokyocabinet_class::OREADER)

    FileUtils.mkdir_p File.dirname(path) unless File.exists?(File.dirname(path))

    database = TC_CONNECTIONS[path] ||= tokyocabinet_class.new
    database.close

    if !database.open(path, flags)
      ecode = database.ecode
      raise "Open error: #{database.errmsg(ecode)}. Trying to open file #{path}"
    end

    if not database.respond_to? :old_close
      class << database
        attr_accessor :writable, :closed, :persistence_path, :tokyocabinet_class

        def closed?
          @closed
        end

        alias old_close close
        def close
          @closed = true
          old_close
        end

        def read(force = false)
          return if not write? and not closed and not force
          self.close
          if !self.open(@persistence_path, tokyocabinet_class::OREADER)
            ecode = self.ecode
            raise "Open error: #{self.errmsg(ecode)}. Trying to open file #{@persistence_path}"
          end
          @writable = false
          @closed = false
          self
        end

        def write(force = true)
          return if write? and not closed and not force
          self.close

          if !self.open(@persistence_path, tokyocabinet_class::OWRITER)
            ecode = self.ecode
            raise "Open error: #{self.errmsg(ecode)}. Trying to open file #{@persistence_path}"
          end

          @writable = true
          @closed = false
          self
        end

        def write?
          @writable
        end

        def collect
          res = []
          each do |key, value|
            res << if block_given?
                     yield key, value
            else
              [key, value]
            end
          end
          res
        end

        def delete(key)
          out(key)
        end

        def write_and_close
          write if @closed or not write?
          res = yield
          close
          res
        end

        def read_and_close
          read if @closed or write?
          res = yield
          close
          res
        end

        def merge!(hash)
          hash.each do |key,values|
            self[key] = values
          end
        end

        if instance_methods.include? "range"
          alias old_range range

          def range(*args)
            keys = old_range(*args)
            keys - TSV::ENTRY_KEYS
          end
        end
      end
    end

    database.persistence_path ||= path
    database.tokyocabinet_class = tokyocabinet_class

    TSV.setup database
    database.serializer = serializer || database.serializer 

    database
  end

  def self.persist_tsv(source, filename, options = {}, persist_options = {})
    persist_options[:prefix] ||= "TSV"

    data = case
           when persist_options[:data]
             persist_options[:data]
           when persist_options[:persist]

             filename ||= source.filename if source.respond_to? :filename
             filename ||= source.object_id.to_s

             path = persistence_path(filename, persist_options, options)

             if is_persisted? path
               Log.debug "TSV persistence up-to-date: #{ path }"
               return Misc.lock(path) do open_tokyocabinet(path, false); end
             else
               Log.debug "TSV persistence creating: #{ path }"
             end

             FileUtils.rm path if File.exists? path

             data = open_tokyocabinet(path, true, persist_options[:serializer])
             data.serializer = :type unless data.serializer

             data.close

             data
           else
             {}
           end

    begin
      if data.respond_to? :persistence_path and data != persist_options[:data]
        Misc.lock data.persistence_path do
          data.write_and_close do
            yield data
          end
        end
      else
        yield data
      end
    rescue Exception
      begin
        data.close if data.respondo_to? :close
      rescue
      end
      FileUtils.rm path if path and File.exists? path
      raise $!
    end

    data.read if data.respond_to? :read and ((data.respond_to?(:write?) and data.write?) or (data.respond_to?(:closed?) and data.closed?))

    data
  end

end
