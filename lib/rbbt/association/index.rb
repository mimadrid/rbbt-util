require 'rbbt/tsv'
module Association
  module Index

    attr_accessor :source_field, :target_field, :undirected
    def parse_key_field
      @source_field, @target_field, @undirected = key_field.split("~")
    end

    def self.setup(repo)
      repo.extend Association::Index
      repo.parse_key_field
      repo.unnamed = true
    end

    def reverse
      @reverse ||= begin
                     reverse_filename = persistence_path + '.reverse'

                     if File.exists?(reverse_filename)
                       new = Persist.open_tokyocabinet(reverse_filename, false, serializer, TokyoCabinet::BDB)
                     else
                       new = Persist.open_tokyocabinet(reverse_filename, true, serializer, TokyoCabinet::BDB)
                       new.write
                       through do |key, value|
                         new_key = key.split("~").reverse.join("~")
                         new[new_key] = value
                       end
                       annotate(new)
                       new.key_field = key_field.split("~").values_at(1,0,2).compact * "~"
                       new.close
                     end

                     new.unnamed = true

                     Association::Index.setup new
                     new
                   end
    end

    def match(entity)
      return [] if entity.nil?
      prefix(entity + "~")
    end

    def matches(entities)
      entities.inject(nil) do |acc,e| 
        m = match(e); 
        if acc.nil? or acc.empty?
          acc = m
        else
          acc.concat m
        end
        acc
      end
    end
 
    #{{{ Subset

    def select_entities(entities)
      source_type = Entity.formats[source_field] 
      target_type = Entity.formats[target_field]

      source_entities = entities[source_field] || entities[Entity.formats[source_field].to_s]  
      target_entities = entities[target_field] || entities[Entity.formats[target_field].to_s]

      [source_entities, target_entities]
    end

    def subset(source, target)
      return [] if source.nil? or source.empty? or target.nil? or target.empty?

      matches = source.uniq.inject([]){|acc,e| acc.concat(match(e)) }

      target_matches = {}

      matches.each{|code| 
        s,sep,t = code.partition "~"
        next if (undirected and t > s) 
        target_matches[t] ||= []
        target_matches[t] << code
      }

      target_matches.values_at(*target.uniq).flatten.compact
    end

    def subset_entities(entities)
      source, target = select_entities(entities)
      subset source, target
    end
  end
end