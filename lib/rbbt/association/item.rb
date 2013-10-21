require 'rbbt/entity'

module AssociationItem
  extend Entity

  annotation :knowledge_base
  annotation :database
  annotation :reverse

  property :part => :array2single do
    self.clean_annotations.collect{|p| p.partition("~") }
  end

  property :target => :array2single do
    self.part.collect{|p| p[2]}
  end

  property :source => :array2single do
    self.clean_annotations.collect{|p| p[/[^~]+/] }
  end

  property :target_entity => :array2single do
    type = reverse ? knowledge_base.source(database) : knowledge_base.target(database)
    knowledge_base.annotate self.target, type if self.target.any?
  end

  property :source_entity => :array2single do
    type = reverse ? knowledge_base.target(database) : knowledge_base.source(database)
    knowledge_base.annotate self.source, type if self.target.any?
  end

  property :value => :array2single do
    value = knowledge_base.get_index(database).chunked_values_at self
    value.collect{|v| NamedArray.setup(v, knowledge_base.get_index(database).fields)}
  end

  property :info => :array2single do
    fields = knowledge_base.index_fields(database)
    return [{}] * self.length if fields.nil? or fields.empty?
    value.collect{|v|
      Hash[*v.zip(fields).flatten]
    }
  end
end