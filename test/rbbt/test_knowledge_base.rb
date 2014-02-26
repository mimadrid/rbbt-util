$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'test/unit'
require 'rbbt/knowledge_base'

require 'rbbt/sources/pina'
require 'rbbt/workflow'

class TestKnowledgeBase < Test::Unit::TestCase
  def setup
    if not defined? Genomics
      Workflow.require_workflow "Genomics"
      require 'genomics_kb'
    end
    KnowledgeBase.knowledge_base_dir = Rbbt.tmp.knowledge_base_test.find
    @kb = Genomics.knowledge_base
  end

  def test_register
    require 'rbbt/sources/pina'

    TmpFile.with_file do |dir|
      kb = KnowledgeBase.new dir

      kb.register :pina, Pina.protein_protein, :target => "Interactor UniProt/SwissProt Accession=~UniProt/SwissProt Accession"
      assert_equal [Gene], kb.entity_types
      assert kb.all_databases.include? :pina
    end
  end

  def test_format_Gene
    TmpFile.with_file do |dir|
      kb = KnowledgeBase.new dir, "Hsa/jan2013"
      kb.format["Gene"] = "Ensembl Gene ID"

      kb.register 'nature', NCI.nature_pathways, :merge => true, :target => "UniProt/SwissProt Accession", :key_field => 0

      assert kb.get_database('nature', :persist => false).slice("Ensembl Gene ID").values.flatten.uniq.length > 10
    end
  end

  def test_fields
    TmpFile.with_file do |dir|
      kb = KnowledgeBase.new dir, "Hsa/jan2013"
      kb.format["Gene"] = "Ensembl Gene ID"

      kb.register 'nature', NCI.nature_pathways, :merge => true, :fields => [2], :key_field => 0
      assert kb.get_database('nature', :persist => false).slice("Ensembl Gene ID").values.flatten.uniq.length > 10
    end
  end

  def test_global
    assert @kb.all_databases.include? "pina"
  end

  def test_subset
    gene = "TP53"
    found = Genomics.knowledge_base.identify :pina, gene
    p53_interactors = Genomics.knowledge_base.children(:pina, found).target_entity 

    assert Genomics.knowledge_base.subset(:pina, {"Gene" => p53_interactors}).target_entity.name.include? "MDM2"
  end

  def test_syndication
    kb = KnowledgeBase.new Rbbt.tmp.test.kb2, "Hsa/jan2013"
    kb.syndicate @kb, :genomics

    gene = "TP53"
    found = kb.identify "pina@genomics", gene
    assert found =~ /ENSG/
  end
end

