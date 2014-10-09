require 'rbbt/association'
require 'rbbt/association/item'

class KnowledgeBase

  def register(name, file = nil, options = {}, &block)
    if block_given?
      block.define_singleton_method(:filename) do name.to_s end
      Log.debug("Registering #{ name } from code block")
      @registry[name] = [block, options]
    else
      Log.debug("Registering #{ name }: #{ Misc.fingerprint file }")
      @registry[name] = [file, options]
    end
  end

  def all_databases
    @registry.keys 
  end

  def description(name)
    @descriptions[name] ||= get_index(name).key_field.split("~")
  end

  def source(name)
    description(name)[0]
  end

  def target(name)
    description(name)[1]
  end

  def undirected(name)
    description(name)[2]
  end

  def get_index(name, options = {})
    name = name.to_s
    key = name.to_s + "_" + Misc.digest(Misc.fingerprint([name,options]))
    @indices[key] ||= 
      begin 
        Persist.memory("Index:" << [key, dir] * "@") do
          options = options.dup
          persist_file = dir.indices[key]
          file, registered_options = registry[name]

          options = Misc.add_defaults options, :persist_file => persist_file, :namespace => namespace, :format => format, :persist => true
          options = Misc.add_defaults options, registered_options if registered_options and registered_options.any?

          persist_options = Misc.pull_keys options, :persist

          index = if persist_file.exists? and persist_options[:persist] and not persist_options[:update]
                    Log.low "Re-opening index #{ name } from #{ Misc.fingerprint persist_file }. #{options}"
                    Association.index(nil, options, persist_options)
                  else
                    options = Misc.add_defaults options, registered_options if registered_options
                    raise "Repo #{ name } not found and not registered" if file.nil?
                    Log.low "Opening index #{ name } from #{ Misc.fingerprint file }. #{options}"
                    Association.index(file, options, persist_options)
                  end

          index.namespace = self.namespace

          index
        end
      end
  end

  def get_database(name, options = {})
    name = name.to_s
    key = "Index:" + name.to_s + "_" + Misc.digest(Misc.fingerprint([name,options.dup]))
    @indices[key] ||= 
      begin 
        Persist.memory("Database:" << [key, dir] * "@") do
          options = options.dup
          persist_file = dir.indices[key]
          file, registered_options = registry[name]

          options = Misc.add_defaults options, :persist_file => persist_file, :namespace => namespace, :format => format, :persist => true
          options = Misc.add_defaults options, registered_options if registered_options and registered_options.any?

          persist_options = Misc.pull_keys options, :persist

          database = if persist_file.exists?
                    Log.low "Re-opening database #{ name } from #{ Misc.fingerprint persist_file }. #{options}"
                    Association.open(nil, options, persist_options)
                  else
                    options = Misc.add_defaults options, registered_options if registered_options
                    raise "Repo #{ name } not found and not registered" if file.nil?
                    Log.low "Opening database #{ name } from #{ Misc.fingerprint file }. #{options}"
                    Association.open(file, options, persist_options)
                  end

          database.namespace = self.namespace

          database
        end
      end
  end

  def index_fields(name)
    get_index(name).fields
  end

  def identifier_files(name)
    get_database(name).identifier_files
  end

  def source_index(name)
    identifier_files = identifier_files(name)
    identifier_files << Organism.identifiers(namespace).find
    identifier_files.uniq!
    TSV.translation_index identifier_files, source(name), nil, :persist => true
  end
  
  def identify_source(name, entity)
    return :all if entity == :all
    index = source_index(name)
    index.values_at *entity
  end

  def target_index(name)
    identifier_files = identifier_files(name)
    identifier_files << Organism.identifiers(namespace).find
    identifier_files.uniq!
    TSV.translation_index identifier_files, target(name), nil, :persist => true
  end
  
  def identify_target(name, entity)
    return :all if entity == :all
    index = target_index(name)
    index.values_at *entity
  end
end
