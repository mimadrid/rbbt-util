require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/util/tsv/filters'

class TestTSVFilters < Test::Unit::TestCase
  def test_collect
    content1 =<<-EOF
#: :sep=/\\s+/#:case_insensitive=false
#Id    ValueA    ValueB
row1    a|aa|aaa    b
row2    A    B
    EOF

    TmpFile.with_file(content1) do |filename|
      tsv = TSV.new filename
      tsv.filter
      tsv.add_filter "field:ValueA", ["A"]
      assert_equal 1, tsv.collect.size
    end
  end

  def test_through
    content1 =<<-EOF
#: :sep=/\\s+/#:case_insensitive=false
#Id    ValueA    ValueB
row1    a|aa|aaa    b
row2    A    B
    EOF

    TmpFile.with_file(content1) do |filename|
      tsv = TSV.new filename
      tsv.filter
      tsv.add_filter "field:ValueA", ["A"]
      elem = []
      tsv.through do |k,v| elem << k end
      assert_equal 1, elem.size
    end
  end

  def test_2_filters
    content1 =<<-EOF
#: :sep=/\\s+/#:case_insensitive=false
#Id    ValueA    ValueB
row1    a|aa|aaa    b
row2    A    B
row3    A    C
    EOF

    TmpFile.with_file(content1) do |filename|
      tsv = TSV.new filename
      tsv.filter
      tsv.add_filter "field:ValueA", ["A"]

      elem = []
      tsv.through do |k,v| elem << k end
      assert_equal 2, elem.size

      tsv.add_filter "field:ValueB", ["C"]

      elem = []
      tsv.through do |k,v| elem << k end
      assert_equal 1, elem.size
    end
  end

  def test_filter_persistence
    content1 =<<-EOF
#: :sep=/\\s+/#:case_insensitive=false
#Id    ValueA    ValueB
row1    a|aa|aaa    b
row2    A    B
row3    A    C
    EOF

    TmpFile.with_file(content1) do |filename|
      tsv = TSV.new filename
      tsv.filter
      tsv.add_filter "field:ValueA", ["A"], Rbbt.tmp.test.Filter.fieldValueA

      elem = []
      tsv.through do |k,v| elem << k end
      assert_equal 2, elem.size

      tsv.add_filter "field:ValueB", ["C"]

      elem = []
      tsv.through do |k,v| elem << k end
      assert_equal 1, elem.size

      tsv = TSV.new filename
      tsv.filter
      tsv.add_filter "field:ValueA", ["A"], Rbbt.tmp.test.Filter.fieldValueA

      elem = []
      tsv.through do |k,v| elem << k end
      assert_equal 2, elem.size
    end
  end

  def test_filter_persistence_update
    content1 =<<-EOF
#: :sep=/\\s+/#:case_insensitive=false
#Id    ValueA    ValueB
row1    a|aa|aaa    b
row2    A    B
    EOF

    TmpFile.with_file(content1) do |filename|
      tsv = TSV.new filename
      tsv.filter
      tsv.add_filter "field:ValueA", ["A"], Rbbt.tmp.test.Filter.fieldValueA.find(:user)

      elem = []
      tsv.through do |k,v| elem << k end
      assert_equal 1, elem.size

      tsv["row3"] = [["A"], ["C"]]

      elem = []
      tsv.through do |k,v| elem << k end
      assert_equal 2, elem.size

      tsv.add_filter "field:ValueB", ["C"]

      elem = []
      tsv.through do |k,v| elem << k end
      assert_equal 1, elem.size

      tsv = TSV.new filename
      tsv.filter
      tsv.add_filter "field:ValueA", ["A"], Rbbt.tmp.test.Filter.fieldValueA.find(:user)

      elem = []
      tsv.through do |k,v| elem << k end
      assert_equal 2, elem.size
    end
  end



end

