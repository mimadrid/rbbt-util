# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rbbt-util}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Miguel Vazquez"]
  s.date = %q{2010-11-19}
  s.default_executable = %q{excel2tsv.rb}
  s.description = %q{Utilities for handling tsv files, caches, etc}
  s.email = %q{miguel.vazquez@fdi.ucm.es}
  s.executables = ["excel2tsv.rb"]
  s.extra_rdoc_files = [
    "LICENSE"
  ]
  s.files = [
    "lib/rbbt/util/base.rb",
    "lib/rbbt/util/cachehelper.rb",
    "lib/rbbt/util/cmd.rb",
    "lib/rbbt/util/filecache.rb",
    "lib/rbbt/util/misc.rb",
    "lib/rbbt/util/open.rb",
    "lib/rbbt/util/pkg_config.rb",
    "lib/rbbt/util/simpleDSL.rb",
    "lib/rbbt/util/simpleopt.rb",
    "lib/rbbt/util/tc_hash.rb",
    "lib/rbbt/util/tmpfile.rb",
    "lib/rbbt/util/tsv.rb"
  ]
  s.homepage = %q{http://github.com/mikisvaz/rbbt-util}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Utilities for the Ruby Bioinformatics Toolkit (rbbt)}
  s.test_files = [
    "test/rbbt/util/test_base.rb",
    "test/rbbt/util/test_cmd.rb",
    "test/rbbt/util/test_filecache.rb",
    "test/rbbt/util/test_misc.rb",
    "test/rbbt/util/test_open.rb",
    "test/rbbt/util/test_simpleDSL.rb",
    "test/rbbt/util/test_tc_hash.rb",
    "test/rbbt/util/test_tmpfile.rb",
    "test/rbbt/util/test_tsv.rb",
    "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<stemmer>, [">= 0"])
    else
      s.add_dependency(%q<stemmer>, [">= 0"])
    end
  else
    s.add_dependency(%q<stemmer>, [">= 0"])
  end
end

