require File.join(File.expand_path(File.dirname(__FILE__)), '../../', 'test_helper.rb')
require 'rbbt/tsv'
require 'rbbt/tsv/manipulate'

class TestTSVManipulate < Test::Unit::TestCase

  def test_zipped
    content =<<-EOF
#Id    ValueA    ValueB ValueC
rowA    A|AA    B|BB  C|CC
rowa    a|aa    b|BB  C|CC
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :sep => /\s+/, :type => :double)
      Log.tsv tsv
      Log.tsv tsv.reorder("ValueA", nil, :zipped => true)
      assert_equal ["A", "AA", "a", "aa"].sort, tsv.reorder("ValueA", nil, :zipped => true).keys.sort
    end
  end


  def _test_through
    content =<<-EOF
#Id    ValueA    ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
row3    a    C    Id4
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :sep => /\s+/)

      new_key, new_fields = tsv.through "ValueA" do |key, values|
        assert(tsv.keys.include? values["Id"].first)
      end

      assert_equal "ValueA", new_key
    end
  end

  def _test_reorder_simple
    content =<<-EOF
#Id    ValueA    ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
row3    a    C    Id4
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :sep => /\s+/)

      tsv1 = tsv.reorder("ValueA")

      assert_equal "ValueA", tsv1.key_field
      assert_equal ["B"], tsv1["A"]["ValueB"]
      assert_equal ["b","C"], tsv1["a"]["ValueB"]
      assert_equal ["b"], tsv1["aa"]["ValueB"]
      assert_equal %w(Id ValueB OtherID), tsv1.fields

    end
  end

  def _test_reorder_remove_field
    content =<<-EOF
#Id    ValueA    ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
row3    a    C    Id4
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :sep => /\s+/)

      tsv1 = tsv.reorder("ValueA", ["ValueB", "Id"])

      assert_equal "ValueA", tsv1.key_field
      assert_equal %w(ValueB Id), tsv1.fields
      assert_equal ["B"], tsv1["A"]["ValueB"]
      assert_equal ["b","C"], tsv1["a"]["ValueB"]
      assert_equal ["row1"], tsv1["aa"]["Id"]
      assert_equal ["row1","row3"], tsv1["a"]["Id"]
    end
  end

  def _test_slice
    content =<<-EOF
#ID ValueA ValueB Comment
row1 a b c
row2 A B C
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :type => :double, :sep => /\s/)
      assert_equal [["a"],["c"]], tsv.reorder(:key, ["ValueA", "Comment"])["row1"]
    end
  end

  def _test_select
     content =<<-EOF
#Id    ValueA    ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
row3    a    C    Id4
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/)
      assert tsv.type == :double
      
      new = tsv.select %w(b Id4)
      assert_equal %w(row1 row3).sort, new.keys

      new = tsv.select "ValueB" => %w(b Id4)
      assert_equal %w(row1).sort, new.keys

      new = tsv.select /b|Id4/
      assert_equal %w(row1 row3).sort, new.keys

      new = tsv.select "ValueB" => /b|Id4/
      assert_equal %w(row1).sort, new.keys

      
      new = tsv.select %w(b Id4)
      assert_equal %w(row1 row3).sort, new.keys.sort

      new = tsv.select do |k,v| 
        v["ValueA"].include? "A" 
      end
      assert_equal %w(row2).sort, new.keys.sort

      tsv = TSV.open(filename, :sep => /\s+/, :type => :flat)
      assert tsv.type != :double
    end
  end

  def _test_select_invert
     content =<<-EOF
#Id    ValueA    ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
row3    a    C    Id4
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/)
      assert tsv.type == :double
      
      new = tsv.select %w(b Id4), true
      assert_equal %w(row2).sort, new.keys

      new = tsv.select /b|Id4/, true
      assert_equal %w(row2).sort, new.keys
      
      new = tsv.select %w(b Id4)
      assert_equal %w(row1 row3).sort, new.keys.sort

      new = tsv.select do |k,v| 
        v["ValueA"].include? "A" 
      end
      assert_equal %w(row2).sort, new.keys.sort

      tsv = TSV.open(filename, :sep => /\s+/, :type => :flat)
      assert tsv.type != :double
    end
  end

  def _test_process
    content =<<-EOF
#Id    ValueA    ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
row3    a    C    Id4
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :sep => /\s+/)

      tsv.process "ValueA" do |field_values,key,values|
        field_values.collect{|v| "Pref:#{v}"}
      end

      assert_equal ["Pref:A"], tsv["row2"]["ValueA"]
    end
  end

  def _test_add_field
     content =<<-EOF
#Id    LetterValue:ValueA    LetterValue:ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
row3    a    C    Id4
    EOF
 
    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/)
      tsv.add_field "Str length" do |k,v| 
        (v.flatten * " ").length 
      end

      assert tsv.fields.include?("Str length")
    end
  end

  def _test_add_field_double_with_list_result
     content =<<-EOF
#Id    LetterValue:ValueA    LetterValue:ValueB    OtherID
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
row3    a    C    Id4
    EOF
 
    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/)

      tsv.add_field "Test" do
        "test"
      end

      assert Array === tsv["row1"]["Test"]
    end
  end

  def _test_through_headless
     content =<<-EOF
row1    a|aa|aaa    b    Id1|Id2
row2    A    B    Id3
row3    a    C    Id4
    EOF
 
    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/)

      _test = false
      tsv.through do
        _test = true
      end
      assert _test

    end
 
  end

  def _test_reorder_flat
    content =<<-EOF
#Id    ValueA    
row1    a aa aaa
row2    A
row3    a
    EOF

    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(File.open(filename), :sep => /\s+/, :type => :flat)
      
      assert_equal ["row1", "row3"].sort, tsv.reorder("ValueA")["a"]

    end
  end

  def _test_transpose
     content =<<-EOF
#: :type=:list
#Row   vA   vB   vID
row1    a    b    Id1
row2    A    B    Id3
row3    a    C    Id4
    EOF
 
    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/)

      assert_equal %w(vA vB vID),  tsv.transpose("Values").keys

    end
 
  end

  def _test_through_flat
     content =<<-EOF
#: :type=:flat
#Row   vA
row1    a    b    Id1
row2    A    B    Id3
row3    a    C    Id4
    EOF
 
    TmpFile.with_file(content) do |filename|
      tsv = TSV.open(filename, :sep => /\s+/)
      tsv.through :key, ["vA"] do |k,v|
        assert_equal 3, v.length
      end


    end
  end
end
