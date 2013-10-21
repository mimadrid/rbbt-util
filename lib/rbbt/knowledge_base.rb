require 'rbbt/association'
require 'rbbt/association/item'
require 'rbbt/entity'

class KnowledgeBase
  class << self
    attr_accessor :knowledge_base_dir, :registry

    def registry
      @registry ||= IndiferentHash.setup({})
    end
    
    def knowledge_base_dir
      @knowledge_base_dir ||= Rbbt.var.knowledge_base
    end
  end

  attr_accessor :namespace, :dir, :indices, :registry, :format, :databases, :entity_options
  def initialize(dir, namespace = nil)
    @dir = Path.setup dir

    @namespace = namespace
    @format = IndiferentHash.setup({})

    @registry = IndiferentHash.setup({})
    @entity_options = IndiferentHash.setup({})

    @indices = IndiferentHash.setup({})
    @databases = IndiferentHash.setup({})
    @identifiers = IndiferentHash.setup({})
    @descriptions = {}
    @databases = {}
  end

  def version(new_namespace, force = false)
    return self if new_namespace == namespace and not force
    new_kb = KnowledgeBase.new dir[new_namespace], new_namespace
    new_kb.format.merge! self.format
    new_kb.entity_options.merge! self.entity_options
    new_kb.registry = self.registry
    new_kb
  end

  #{{{ Descriptions
 
  def register(name, file = nil, options = {}, &block)
    if block_given?
      Log.debug("Registering #{ name } from code block")
      @registry[name] = [block, options]
    else
      Log.debug("Registering #{ name }: #{ Misc.fingerprint file }")
      @registry[name] = [file, options]
    end
  end

  def all_databases
    (@indices.keys + @registry.keys).uniq
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

  def source_type(name)
    Entity.formats[source(name)]
  end

  def target_type(name)
    Entity.formats[target(name)]
  end

  def index_fields(name)
    get_index(name).fields
  end

  def entities
    all_databases.inject([]){|acc,name| acc << source(name); acc << target(name)}.uniq
  end

  def entity_types
    entities.collect{|entity| Entity.formats[entity] }.uniq
  end

  #{{{ Open and get
 
  def open_options
    {:namespace => namespace, :format => @format}
  end
 
  def get_database(name, options = {})
    persist_options = Misc.pull_keys options, :persist

    file, registered_options = registry[name]
    options = open_options.merge(registered_options || {}).merge(options)
    raise "Repo #{ name } not found and not registered" if file.nil?

    @databases[name] ||= begin 
                           Log.debug "Opening database #{ name } from #{ Misc.fingerprint file }. #{options}"
                           Association.open(file, options, persist_options).
                             tap{|tsv| tsv.namespace = self.namespace}
                         end
  end

 
  def get_index(name, options = {})
    persist_options = Misc.pull_keys options, :persist

    file, registered_options = registry[name]
    options = open_options.merge(registered_options || {}).merge(options)
    raise "Repo #{ name } not found and not registered" if file.nil?

    @indices[name] ||= begin 
                           Log.debug "Opening index #{ name } from #{ Misc.fingerprint file }. #{options}"
                           Association.index(file, options, persist_options).
                             tap{|tsv| tsv.namespace = self.namespace}
                         end
  end

  def index(name, file, options = {}, persist_options = {})
    @indices[name] = Association.index(file, open_options.merge(options), persist_options)
  end

  #{{{ Add manual database
  
  def add_index(name, source_type, target_type, *fields)
    options = fields.pop if Hash === fields.last
    options ||= {}
    undirected = Misc.process_options options, :undirected 

    undirected = nil unless undirected 

    repo_file = dir[name].find
    index = Association.index(nil, {:namespace => namespace, :key_field => [source_type, target_type, undirected].compact * "~", :fields => fields}.merge(options), :file => repo_file, :update => true)
    @indices[name] = index
  end

  def add(name, source, target, *rest)
    code = [source, target] * "~"
    repo = @indices[name]
    repo[code] = rest
  end

  def write(name)
    repo = @indices[name]
    repo.write_and_read do
      yield
    end
  end

  #{{{ Annotate
  
  def entity_options_for(type)
    options = entity_options[Entity.formats[type]] || {}
    options[:format] = @format[type] if @format.include? :type
    options = {:organism => namespace}.merge(options)
    options
  end

  def annotate(entities, type)
    Misc.prepare_entity(entities, type, entity_options_for(type))
  end

  #{{{ Identify
  
  def identify_source(name, entity)
    database = get_database(name, :persist => true)
    return entity if database.include? entity
    source = source(name)
    @identifiers[name] ||= {}
    @identifiers[name]['source'] ||= begin
                                       if database.identifier_files.any?
                                         if TSV.parse_header(database.identifier_files.first).all_fields.include? source
                                           TSV.index(database.identifiers, :target => source, :persist => true)
                                         else
                                           {}
                                         end
                                       else
                                         if TSV.parse_header(Organism.identifiers(namespace)).all_fields.include? source
                                           Organism.identifiers(namespace).index(:target => source, :persist => true)
                                         else
                                           {}
                                         end
                                       end
                                     end

    @identifiers[name]['source'][entity]
  end

  def identify_target(name, entity)
    database = get_database(name, :persist => true)
    target = target(name)

    @identifiers[name] ||= {}
    @identifiers[name]['target'] ||= begin
                                       if database.identifier_files.any?
                                         if TSV.parse_header(database.identifier_files.first).all_fields.include? target
                                           TSV.index(database.identifiers, :target => target, :persist => true)
                                         else
                                           {}
                                         end
                                       else
                                         if TSV.parse_header(Organism.identifiers(namespace)).all_fields.include? target
                                           Organism.identifiers(namespace).index(:target => target, :persist => true)
                                         else
                                          database.index(:target => database.fields.first, :fields => [database.fields.first], :persist => true)
                                         end
                                       end
                                     end
    @identifiers[name]['target'][entity]
  end

  def identify(name, entity)
    identify_source(name, entity) || identify_target(name, entity)
  end

  #{{{ Query

  def children(name, entity)
    repo = get_index name
    AssociationItem.setup repo.match(entity), self, name, false
  end

  def parents(name, entity)
    repo = get_index name
    AssociationItem.setup repo.reverse.match(entity), self, name, true
  end

  def neighbours(name, entity)
    if undirected(name)
      IndiferentHash.setup({:children => children(name, entity)})
    else
      IndiferentHash.setup({:parents => parents(name, entity), :children => children(name, entity)})
    end
  end

  def subset(name, entities)
    case entities
    when AnnotatedArray
      format = entities.format if entities.respond_to? :format 
      format ||= entities.base_entity.to_s
      {format => entities.clean_annotations}
    when Hash
    else
      raise "Entities are not a Hash or an AnnotatedArray: #{Misc.fingerprint entities}"
    end
    repo = get_index name
    AssociationItem.setup repo.subset_entities(entities), self, name, false
  end

  def translate(entities, type)
    if format = @format[type] and format != entities.format
      entities.to format
    else
      entities
    end
  end
end
