require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'rbbt/util/open'
require 'rbbt/util/tmpfile'
require 'rbbt/persist'
require 'test/unit'


class TestOpen < Test::Unit::TestCase

  def test_wget
    assert(Misc.fixutf8(Open.wget('http://google.com', :quiet => true).read) =~ /html/)
  end

  def test_nice
    nice =  0.5

    t = Time.now
    Open.wget('http://google.com', :quiet => true, :nice => nice).read
    assert(Time.now - t + 0.5 >= nice)

    Open.wget('http://google.com', :quiet => true, :nice => nice, :nice_key => 1).read
    t = Time.now
    Open.wget('http://google.com', :quiet => true, :nice => nice, :nice_key => 1).read
    assert(Time.now - t + 0.5 >= nice)
  end

  def test_remote?
    assert(Open.remote?('http://google.com'))
    assert(! Open.remote?('~/.bashrc'))
  end

  def test_open
    assert(Open.read('http://google.com', :quiet => true, :nocache => :update) =~ /html/)
  end

  def test_read
    content =<<-EOF
1
2
3
4
    EOF
    TmpFile.with_file(content) do |file|
      sum = 0
      Open.read file do |line| sum += line.to_i end
      assert_equal(1 + 2 + 3 + 4, sum)
      assert_equal(content, Open.read(file))
    end
  end

  def test_read_grep
    content =<<-EOF
1
2
3
4
    EOF
    TmpFile.with_file(content) do |file|
      sum = 0
      Open.read(file, :grep => '^1\|3') do |line| sum += line.to_i end
      assert_equal(1 + 3, sum)
    end

    TmpFile.with_file(content) do |file|
      sum = 0
      Open.read(file, :grep => ["1","3"]) do |line| sum += line.to_i end
      assert_equal(1 + 3, sum)
    end
  end

  def test_read_grep_invert
    content =<<-EOF
1
2
3
4
    EOF
    TmpFile.with_file(content) do |file|
      sum = 0
      Open.read(file, :grep => '^1\|3', :invert_grep => true) do |line| sum += line.to_i end
      assert_equal(2 + 4, sum)
    end

    TmpFile.with_file(content) do |file|
      sum = 0
      Open.read(file, :grep => ["1","3"]) do |line| sum += line.to_i end
      assert_equal(1 + 3, sum)
    end

  end


  def test_gzip
    content =<<-EOF
1
2
3
4
    EOF
    TmpFile.with_file(content) do |file|
      `bgzip #{file}`
      assert_equal(content, Open.read(file + '.gz'))
      puts content
      FileUtils.rm file + '.gz'
    end
  end

  def test_repo_dir
    file1 = "TEST"
    file2 = "TEST" * 1000
    TmpFile.with_file do |tmpdir|
      tmpdir = "/home/mvazquezg/tmp/repo_dir"
      normal = File.join(tmpdir, 'normal')
      repo = File.join(tmpdir, 'repo')

      Open.repository_dirs.push(repo)

      Misc.benchmark(100) do
        filename = "file" << (rand * 100).to_i.to_s
        Open.write(File.join(normal, filename), file2)
        100.times do 
          Open.read(File.join(normal,  filename))
        end
      end

      Misc.benchmark(100) do
        filename = "file" << (rand * 100).to_i.to_s
        Open.write(File.join(repo, filename), file2)
        100.times do 
          Open.read(File.join(repo, filename))
        end
      end
    end
  end
  
  def test_repo_dir2
    TmpFile.with_file do |tmpdir|
      tmpdir = "/home/mvazquezg/tmp/repo_dir"
      repo = File.join(tmpdir, 'repo')

      Open.repository_dirs.push(repo)

      obj = { :a => "???a"}
      filename = "file" << (rand * 100).to_i.to_s
      Open.write(File.join(repo, filename), Marshal.dump(obj))
      dump = Open.read(File.join(repo, filename))
      obj_cp = Marshal.load(dump)
      assert_equal obj, obj_cp
    end
  end

end

