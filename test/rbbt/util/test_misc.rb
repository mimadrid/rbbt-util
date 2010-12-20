require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'rbbt/util/misc'
require 'test/unit'

class TestMisc < Test::Unit::TestCase

  def test_pdf2text_example
    assert PDF2Text.pdf2text(test_datafile('example.pdf')).read =~ /An Example Paper/i
  end

  def test_pdf2text_EPAR
    assert PDF2Text.pdf2text("http://www.ema.europa.eu/docs/en_GB/document_library/EPAR_-_Scientific_Discussion/human/000402/WC500033103.pdf").read =~ /Tamiflu/i
  end

  def test_pdf2text_wrong
    assert_raise CMD::CMDError do PDF2Text.pdf2text("http://www.ema.europa.eu/docs/en_GB#") end
  end

  def test_string2hash
    assert(Misc.string2hash("--user-agent=firefox").include? "--user-agent")
    assert(Misc.string2hash(":true")[:true] == true)
    assert(Misc.string2hash("true")["true"] == true)
    assert(Misc.string2hash("a=1")["a"] == 1)
    assert(Misc.string2hash("a=b")["a"] == 'b')
    assert(Misc.string2hash("a=b#c=d#:h=j")["c"] == 'd')
    assert(Misc.string2hash("a=b#c=d#:h=j")[:h] == 'j')
  end
  
  def test_named_array
    a = NamedArray.name([1,2,3,4], %w(a b c d))
    assert_equal(1, a['a'])
  end

end
