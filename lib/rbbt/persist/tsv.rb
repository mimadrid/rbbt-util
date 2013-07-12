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

        def prefix(key)
          range(key, 1, key + 255.chr, 1)
        end

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
          lock_filename = Persist.persistence_path(persistence_path, {:dir => TSV.lock_dir})
          Misc.lock(lock_filename) do
            write if @closed or not write?
            res = begin
                    yield
                  ensure
                    close
                  end
            res
          end
        end

        def read_and_close
          read if @closed or write?
          res = begin
                  yield
                ensure
                  close
                end
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

    unless serializer == :clean
      TSV.setup database
      database.serializer = serializer || database.serializer
      database.fields
    end

    database
  end

  def self.persist_tsv(source, filename, options = {}, persist_options = {})
    persist_options[:prefix] ||= "TSV"

    data = case
           when persist_options[:data]
             persist_options[:data]
           when persist_options[:persist]

             filename ||= case
                          when Path === source
                            source
                          when source.respond_to?(:filename)
                            source.filename
                          when source.respond_to?(:cmd)
                            "CMD-#{Misc.digest(source.cmd)}"
                          else
                            source.object_id.to_s
                          end

             filename ||= source.object_id.to_s

             path = persistence_path(filename, persist_options, options)

             if is_persisted? path and not persist_options[:update]
               Log.debug "TSV persistence up-to-date: #{ path }"
               lock_filename = Persist.persistence_path(path, {:dir => Rbbt.tmp.tsv_open_locks.find})
               return Misc.lock(lock_filename) do open_tokyocabinet(path, false, nil, persist_options[:engine] || TokyoCabinet::HDB); end
             else
               Log.medium "TSV persistence creating: #{ path }"
             end

             FileUtils.rm path if File.exists? path

             data = open_tokyocabinet(path, true, persist_options[:serializer], persist_options[:engine] || TokyoCabinet::HDB)
             data.serializer = :type if TSV === data and data.serializer.nil?

             data.close

             data
           else
             {}
           end

    begin
      if data.respond_to? :persistence_path and data != persist_options[:data]
        data.write_and_close do
          yield data
        end
      else
        yield data
      end
    rescue Exception
      FileUtils.rm path if path and File.exists? path
      raise $!
    ensure
      begin
        data.close if data.respond_to? :close
      rescue
        raise $!
      end
    end

    data.read if data.respond_to? :read and ((data.respond_to?(:write?) and data.write?) or (data.respond_to?(:closed?) and data.closed?))


    data
  end
end
