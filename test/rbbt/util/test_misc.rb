require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'rbbt/util/misc'
require 'test/unit'

class TestMisc < Test::Unit::TestCase

  def _test_pdf2text_example
    assert PDF2Text.pdf2text(test_datafile('example.pdf')).read =~ /An Example Paper/i
  end

  def _test_pdf2text_EPAR
    assert PDF2Text.pdf2text("http://www.ema.europa.eu/docs/en_GB/document_library/EPAR_-_Scientific_Discussion/human/000402/WC500033103.pdf").read =~ /Tamiflu/i
  end

  def _test_pdf2text_wrong
    assert_raise CMD::CMDError do PDF2Text.pdf2text("http://www.ema.europa.eu/docs/en_GB#") end
  end

  def _test_string2hash
    assert(Misc.string2hash("--user-agent=firefox").include? "--user-agent")
    assert(Misc.string2hash(":true")[:true] == true)
    assert(Misc.string2hash("true")["true"] == true)
    assert(Misc.string2hash("a=1")["a"] == 1)
    assert(Misc.string2hash("a=b")["a"] == 'b')
    assert(Misc.string2hash("a=b#c=d#:h=j")["c"] == 'd')
    assert(Misc.string2hash("a=b#c=d#:h=j")[:h] == 'j')
    assert(Misc.string2hash("a=b#c=d#:h=:j")[:h] == :j)
  end
  
  def _test_named_array
    a = NamedArray.name([1,2,3,4], %w(a b c d))
    assert_equal(1, a['a'])
  end

  def _test_path_relative_to
    assert_equal "test/foo", Misc.path_relative_to('test/test/foo', 'test')
  end

  def _test_chunk
    _test =<<-EOF
This is an example file. Entries are separated by Entry
-- Entry
1
2
3
-- Entry
4
5
6
    EOF

    assert_equal "1\n2\n3", Misc.chunk(test, /^-- Entry/).first.strip
  end

  def _test_hash2string
    hash = {}
    assert_equal hash, Misc.string2hash(Misc.hash2string(hash))

    hash = {:a => 1}
    assert_equal hash, Misc.string2hash(Misc.hash2string(hash))
 
    hash = {:a => true}
    assert_equal hash, Misc.string2hash(Misc.hash2string(hash))

    hash = {:a => Misc}
    assert_equal hash, Misc.string2hash(Misc.hash2string(hash))
 
    hash = {:a => :b}
    assert_equal hash, Misc.string2hash(Misc.hash2string(hash))
 
    hash = {:a => /test/}
    assert_equal({}, Misc.string2hash(Misc.hash2string(hash)))
 
 end

  def _test_merge
    a = [[1],[2]]
    a = NamedArray.name a, %w(1 2)
    a.merge [3,4]
    assert_equal [1,3], a[0]
  end

  def _test_indiferent_hash
    a = {:a => 1, "b" => 2}
    a.extend IndiferentHash

    assert 1, a["a"]
    assert 1, a[:a]
    assert 2, a["b"]
    assert 2, a[:b]
  end

  def test_lockfile
    TmpFile.with_file do |tmpfile|
      pids = []
      3.times do |i|
        pids << Process.fork do 
          pid = pid.to_s
          Misc.lock(tmpfile, pid) do |f, val|
            Open.write(f, val)
            sleep rand * 2
            if pid == Open.read(tmpfile)
              exit(0)
            else
              exit(1)
            end
          end
        end
      end
      pids.each do |pid| Process.waitpid pid; assert $?.success? end
    end

  end

end
