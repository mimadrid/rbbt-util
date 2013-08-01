# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rbbt-util"
  s.version = "5.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Miguel Vazquez"]
  s.date = "2013-08-01"
  s.description = "Utilities for handling tsv files, caches, etc"
  s.email = "miguel.vazquez@cnio.es"
  s.executables = ["tsv.rb", "tchash.rb", "run_workflow.rb", "rbbt_query.rb", "rbbt_exec.rb", "rbbt_Rutil.rb", "rbbt_monitor.rb", "rbbt", "rbbt_dangling_locks.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "LICENSE",
    "lib/rbbt-util.rb",
    "lib/rbbt.rb",
    "lib/rbbt/annotations.rb",
    "lib/rbbt/annotations/annotated_array.rb",
    "lib/rbbt/annotations/util.rb",
    "lib/rbbt/entity.rb",
    "lib/rbbt/fix_width_table.rb",
    "lib/rbbt/persist.rb",
    "lib/rbbt/persist/tsv.rb",
    "lib/rbbt/resource.rb",
    "lib/rbbt/resource/path.rb",
    "lib/rbbt/resource/rake.rb",
    "lib/rbbt/resource/util.rb",
    "lib/rbbt/resource/with_key.rb",
    "lib/rbbt/tsv.rb",
    "lib/rbbt/tsv/accessor.rb",
    "lib/rbbt/tsv/attach.rb",
    "lib/rbbt/tsv/attach/util.rb",
    "lib/rbbt/tsv/excel.rb",
    "lib/rbbt/tsv/filter.rb",
    "lib/rbbt/tsv/index.rb",
    "lib/rbbt/tsv/manipulate.rb",
    "lib/rbbt/tsv/parser.rb",
    "lib/rbbt/tsv/serializers.rb",
    "lib/rbbt/tsv/util.rb",
    "lib/rbbt/util/R.rb",
    "lib/rbbt/util/chain_methods.rb",
    "lib/rbbt/util/cmd.rb",
    "lib/rbbt/util/color.rb",
    "lib/rbbt/util/colorize.rb",
    "lib/rbbt/util/excel2tsv.rb",
    "lib/rbbt/util/filecache.rb",
    "lib/rbbt/util/log.rb",
    "lib/rbbt/util/misc.rb",
    "lib/rbbt/util/named_array.rb",
    "lib/rbbt/util/open.rb",
    "lib/rbbt/util/semaphore.rb",
    "lib/rbbt/util/simpleDSL.rb",
    "lib/rbbt/util/simpleopt.rb",
    "lib/rbbt/util/task/job.rb",
    "lib/rbbt/util/tmpfile.rb",
    "lib/rbbt/workflow.rb",
    "lib/rbbt/workflow/accessor.rb",
    "lib/rbbt/workflow/annotate.rb",
    "lib/rbbt/workflow/definition.rb",
    "lib/rbbt/workflow/soap.rb",
    "lib/rbbt/workflow/step.rb",
    "lib/rbbt/workflow/task.rb",
    "lib/rbbt/workflow/usage.rb",
    "share/install/software/lib/install_helpers",
    "share/lib/R/util.R",
    "share/rbbt_commands/app/start",
    "share/rbbt_commands/conf/web_user/add",
    "share/rbbt_commands/conf/web_user/list",
    "share/rbbt_commands/conf/web_user/remove",
    "share/rbbt_commands/study/task",
    "share/rbbt_commands/tsv/attach",
    "share/rbbt_commands/tsv/change_id",
    "share/rbbt_commands/tsv/info",
    "share/rbbt_commands/workflow/remote/add",
    "share/rbbt_commands/workflow/remote/list",
    "share/rbbt_commands/workflow/remote/remove",
    "share/rbbt_commands/workflow/server",
    "share/rbbt_commands/workflow/task"
  ]
  s.homepage = "http://github.com/mikisvaz/rbbt-util"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "Utilities for the Ruby Bioinformatics Toolkit (rbbt)"
  s.test_files = ["test/rbbt/tsv/test_accessor.rb", "test/rbbt/tsv/test_index.rb", "test/rbbt/tsv/test_util.rb", "test/rbbt/tsv/test_filter.rb", "test/rbbt/tsv/test_attach.rb", "test/rbbt/tsv/test_manipulate.rb", "test/rbbt/test_fix_width_table.rb", "test/rbbt/test_workflow.rb", "test/rbbt/workflow/test_step.rb", "test/rbbt/workflow/test_task.rb", "test/rbbt/workflow/test_soap.rb", "test/rbbt/resource/test_path.rb", "test/rbbt/test_tsv.rb", "test/rbbt/test_resource.rb", "test/rbbt/test_annotations.rb", "test/rbbt/test_entity.rb", "test/rbbt/test_persist.rb", "test/rbbt/util/test_filecache.rb", "test/rbbt/util/test_tmpfile.rb", "test/rbbt/util/test_excel2tsv.rb", "test/rbbt/util/test_simpleopt.rb", "test/rbbt/util/test_colorize.rb", "test/rbbt/util/test_misc.rb", "test/rbbt/util/test_open.rb", "test/rbbt/util/test_cmd.rb", "test/rbbt/util/test_chain_methods.rb", "test/rbbt/util/test_R.rb", "test/rbbt/util/test_simpleDSL.rb", "test/test_rbbt.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<spreadsheet>, [">= 0"])
      s.add_runtime_dependency(%q<ruby-prof>, [">= 0"])
      s.add_runtime_dependency(%q<tokyocabinet>, [">= 0"])
      s.add_runtime_dependency(%q<progress-monitor>, [">= 0"])
      s.add_runtime_dependency(%q<lockfile>, [">= 0"])
      s.add_runtime_dependency(%q<RubyInline>, [">= 0"])
      s.add_runtime_dependency(%q<narray>, [">= 0"])
      s.add_runtime_dependency(%q<simplews>, [">= 0"])
      s.add_runtime_dependency(%q<highline>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<spreadsheet>, [">= 0"])
      s.add_dependency(%q<ruby-prof>, [">= 0"])
      s.add_dependency(%q<tokyocabinet>, [">= 0"])
      s.add_dependency(%q<progress-monitor>, [">= 0"])
      s.add_dependency(%q<lockfile>, [">= 0"])
      s.add_dependency(%q<RubyInline>, [">= 0"])
      s.add_dependency(%q<narray>, [">= 0"])
      s.add_dependency(%q<simplews>, [">= 0"])
      s.add_dependency(%q<highline>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<spreadsheet>, [">= 0"])
    s.add_dependency(%q<ruby-prof>, [">= 0"])
    s.add_dependency(%q<tokyocabinet>, [">= 0"])
    s.add_dependency(%q<progress-monitor>, [">= 0"])
    s.add_dependency(%q<lockfile>, [">= 0"])
    s.add_dependency(%q<RubyInline>, [">= 0"])
    s.add_dependency(%q<narray>, [">= 0"])
    s.add_dependency(%q<simplews>, [">= 0"])
    s.add_dependency(%q<highline>, [">= 0"])
  end
end

