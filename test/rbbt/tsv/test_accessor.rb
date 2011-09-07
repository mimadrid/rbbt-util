require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'rbbt/tsv'
require 'rbbt/util/tmpfile'
require 'test/unit'

class TestTSV < Test::Unit::TestCase

  def _test_tsv
    content =<<-EOF
#Id    ValueA    ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/)
      assert_equal 2, tsv.keys.length
      assert_equal 2, tsv.values.length
      assert_equal 2, tsv.collect.length
    end
  end

  def _test_named_values
    content =<<-EOF
#Id    ValueA    ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/)
      assert_equal ["A"], tsv["row2"]["ValueA"]
    end
  end

  def _test_to_s
    content =<<-EOF
#Id    ValueA    ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/)
      assert tsv.to_s =~ /row1\ta|aa|aaa/
      assert tsv.to_s =~ /:type=:double/
    end
  end
  
  def _test_entries
    content =<<-EOF
#Id    ValueA    ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/)
      assert_equal filename, tsv.options[:filename]
    end
 
  end

  def _test_marshal
    content =<<-EOF
#Id    ValueA    ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/, :persist_serializer => :marshal, :persist => true)
      assert_equal filename, tsv.options[:filename]
    end
  end

  def _test_zip_fields
    a = [%w(1 2), %w(a b)]
    assert_equal a, TSV.zip_fields(TSV.zip_fields(a))
  end

  def _test_indentify_fields
    content =<<-EOF
#ID ValueA ValueB Comment
row1 a b c
row2 A B C
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :double, :sep => /\s/)
      assert_equal :key, tsv.identify_field("ID")
    end
  end

  def _test_sort
    content =<<-EOF
#ID ValueA ValueB Comment
row1 a B c
row2 A b C
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :double, :sep => /\s/)
      assert_equal %w(row2 row1), tsv.sort{|a,b|
        a[1]["ValueA"] <=> b[1]["ValueA"]
      }.collect{|k,v| k}
      assert_equal %w(row1 row2), tsv.sort{|a,b|
        a[1]["ValueB"] <=> b[1]["ValueB"]
      }.collect{|k,v| k}
    end
  end

  def _test_sort_by
    content =<<-EOF
#ID ValueA ValueB Comment
row1 a B c
row2 A b C
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :list, :sep => /\s/)
      assert_equal %w(row2 row1), tsv.sort_by("ValueA").collect{|k,v| k}
      assert_equal %w(row1 row2), tsv.sort_by("ValueB").collect{|k,v| k}
    end
  end


  def test_page
    content =<<-EOF
#ID ValueA ValueB Comment
row1 a B f
row2 A b e
row3 A b d
row4 A b c
row5 A b b
row6 A b a
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :list, :sep => /\s/)
      assert_equal 3, tsv.page(1,3).size
      assert_equal %w(row1 row2 row3).sort, tsv.page(1,3).keys.sort
      assert_equal %w(row6 row5 row4).sort, tsv.page(1,3, "Comment").keys.sort
      assert_equal %w(row4 row3).sort, tsv.page(2,2, "Comment").keys.sort
    end
  end


  def _test_sort_by_with_proc
    content =<<-EOF
#Id    ValueA    ValueB    OtherID    Pos
row1    a|aa|aaa    b    Id1|Id2    2
row2    aA    B    Id3    1
row3    A|AA|AAA|AAA    B    Id3    3
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :sep => /\s+/)
      assert_equal %w(row3 row1 row2), (tsv.sort_by("ValueA") do |key, value| value.length end).collect{|k,v| k}.reverse
    end
  end

end
