class KnowledgeBase
  def syndicate(name, kb)
    kb.all_databases.each do |database|
      db_name = [database, name] * "@"
      file, kb_options = kb.registry[database]
      options = {}
      options[:entity_options] = kb_options[:entity_options]
      options[:undirected] = true if kb_options and kb_options[:undirected]
      if kb.entity_options
        options[:entity_options] = kb.entity_options.merge(options[:entity_options] || {})
      end

      register(db_name, nil, options) do
        kb.get_database(database)
      end
    end
  end

  def all_databases
    @registry.keys 
  end
end
