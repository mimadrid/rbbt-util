# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: rbbt-util 5.17.85 ruby lib

Gem::Specification.new do |s|
  s.name = "rbbt-util"
  s.version = "5.17.85"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Miguel Vazquez"]
  s.date = "2015-11-04"
  s.description = "Utilities for handling tsv files, caches, etc"
  s.email = "miguel.vazquez@cnio.es"
  s.executables = ["rbbt_query.rb", "rbbt_exec.rb", "rbbt_Rutil.rb", "rbbt", "rbbt_dangling_locks.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "LICENSE",
    "etc/app.d/base.rb",
    "etc/app.d/entities.rb",
    "etc/app.d/finder.rb",
    "etc/app.d/foundation.rb",
    "etc/app.d/grid_system.rb",
    "etc/app.d/init.rb",
    "etc/app.d/resources.rb",
    "etc/app.d/workflows.rb",
    "lib/rbbt-util.rb",
    "lib/rbbt.rb",
    "lib/rbbt/annotations.rb",
    "lib/rbbt/annotations/annotated_array.rb",
    "lib/rbbt/annotations/util.rb",
    "lib/rbbt/association.rb",
    "lib/rbbt/association/database.rb",
    "lib/rbbt/association/index.rb",
    "lib/rbbt/association/item.rb",
    "lib/rbbt/association/open.rb",
    "lib/rbbt/association/util.rb",
    "lib/rbbt/entity.rb",
    "lib/rbbt/entity/identifiers.rb",
    "lib/rbbt/fix_width_table.rb",
    "lib/rbbt/knowledge_base.rb",
    "lib/rbbt/knowledge_base/enrichment.rb",
    "lib/rbbt/knowledge_base/entity.rb",
    "lib/rbbt/knowledge_base/query.rb",
    "lib/rbbt/knowledge_base/registry.rb",
    "lib/rbbt/knowledge_base/syndicate.rb",
    "lib/rbbt/knowledge_base/traverse.rb",
    "lib/rbbt/monitor.rb",
    "lib/rbbt/packed_index.rb",
    "lib/rbbt/persist.rb",
    "lib/rbbt/persist/tsv.rb",
    "lib/rbbt/persist/tsv/adapter.rb",
    "lib/rbbt/persist/tsv/cdb.rb",
    "lib/rbbt/persist/tsv/fix_width_table.rb",
    "lib/rbbt/persist/tsv/kyotocabinet.rb",
    "lib/rbbt/persist/tsv/leveldb.rb",
    "lib/rbbt/persist/tsv/lmdb.rb",
    "lib/rbbt/persist/tsv/packed_index.rb",
    "lib/rbbt/persist/tsv/sharder.rb",
    "lib/rbbt/persist/tsv/tokyocabinet.rb",
    "lib/rbbt/resource.rb",
    "lib/rbbt/resource/path.rb",
    "lib/rbbt/resource/rake.rb",
    "lib/rbbt/resource/util.rb",
    "lib/rbbt/resource/with_key.rb",
    "lib/rbbt/rest/client.rb",
    "lib/rbbt/rest/client/adaptor.rb",
    "lib/rbbt/rest/client/get.rb",
    "lib/rbbt/rest/client/step.rb",
    "lib/rbbt/tsv.rb",
    "lib/rbbt/tsv/accessor.rb",
    "lib/rbbt/tsv/attach.rb",
    "lib/rbbt/tsv/attach/util.rb",
    "lib/rbbt/tsv/change_id.rb",
    "lib/rbbt/tsv/dumper.rb",
    "lib/rbbt/tsv/excel.rb",
    "lib/rbbt/tsv/field_index.rb",
    "lib/rbbt/tsv/filter.rb",
    "lib/rbbt/tsv/index.rb",
    "lib/rbbt/tsv/manipulate.rb",
    "lib/rbbt/tsv/matrix.rb",
    "lib/rbbt/tsv/melt.rb",
    "lib/rbbt/tsv/parallel.rb",
    "lib/rbbt/tsv/parallel/through.rb",
    "lib/rbbt/tsv/parallel/traverse.rb",
    "lib/rbbt/tsv/parser.rb",
    "lib/rbbt/tsv/serializers.rb",
    "lib/rbbt/tsv/stream.rb",
    "lib/rbbt/tsv/util.rb",
    "lib/rbbt/util/R.rb",
    "lib/rbbt/util/R/eval.rb",
    "lib/rbbt/util/R/model.rb",
    "lib/rbbt/util/R/plot.rb",
    "lib/rbbt/util/chain_methods.rb",
    "lib/rbbt/util/cmd.rb",
    "lib/rbbt/util/color.rb",
    "lib/rbbt/util/colorize.rb",
    "lib/rbbt/util/concurrency.rb",
    "lib/rbbt/util/concurrency/processes.rb",
    "lib/rbbt/util/concurrency/processes/socket.rb",
    "lib/rbbt/util/concurrency/processes/socket_old.rb",
    "lib/rbbt/util/concurrency/processes/worker.rb",
    "lib/rbbt/util/concurrency/threads.rb",
    "lib/rbbt/util/docker.rb",
    "lib/rbbt/util/excel2tsv.rb",
    "lib/rbbt/util/filecache.rb",
    "lib/rbbt/util/log.rb",
    "lib/rbbt/util/log/progress.rb",
    "lib/rbbt/util/log/progress/report.rb",
    "lib/rbbt/util/log/progress/util.rb",
    "lib/rbbt/util/misc.rb",
    "lib/rbbt/util/misc/bgzf.rb",
    "lib/rbbt/util/misc/concurrent_stream.rb",
    "lib/rbbt/util/misc/development.rb",
    "lib/rbbt/util/misc/exceptions.rb",
    "lib/rbbt/util/misc/format.rb",
    "lib/rbbt/util/misc/indiferent_hash.rb",
    "lib/rbbt/util/misc/inspect.rb",
    "lib/rbbt/util/misc/lock.rb",
    "lib/rbbt/util/misc/manipulation.rb",
    "lib/rbbt/util/misc/math.rb",
    "lib/rbbt/util/misc/objects.rb",
    "lib/rbbt/util/misc/omics.rb",
    "lib/rbbt/util/misc/options.rb",
    "lib/rbbt/util/misc/pipes.rb",
    "lib/rbbt/util/misc/progress.rb",
    "lib/rbbt/util/misc/system.rb",
    "lib/rbbt/util/named_array.rb",
    "lib/rbbt/util/open.rb",
    "lib/rbbt/util/semaphore.rb",
    "lib/rbbt/util/simpleDSL.rb",
    "lib/rbbt/util/simpleopt.rb",
    "lib/rbbt/util/simpleopt/accessor.rb",
    "lib/rbbt/util/simpleopt/doc.rb",
    "lib/rbbt/util/simpleopt/get.rb",
    "lib/rbbt/util/simpleopt/parse.rb",
    "lib/rbbt/util/simpleopt/setup.rb",
    "lib/rbbt/util/tar.rb",
    "lib/rbbt/util/task/job.rb",
    "lib/rbbt/util/tmpfile.rb",
    "lib/rbbt/workflow.rb",
    "lib/rbbt/workflow/accessor.rb",
    "lib/rbbt/workflow/annotate.rb",
    "lib/rbbt/workflow/definition.rb",
    "lib/rbbt/workflow/doc.rb",
    "lib/rbbt/workflow/examples.rb",
    "lib/rbbt/workflow/soap.rb",
    "lib/rbbt/workflow/step.rb",
    "lib/rbbt/workflow/step/run.rb",
    "lib/rbbt/workflow/task.rb",
    "lib/rbbt/workflow/usage.rb",
    "share/Rlib/plot.R",
    "share/Rlib/svg.R",
    "share/Rlib/util.R",
    "share/config.ru",
    "share/install/software/lib/install_helpers",
    "share/rbbt_commands/alias",
    "share/rbbt_commands/app/install",
    "share/rbbt_commands/app/start",
    "share/rbbt_commands/app/template",
    "share/rbbt_commands/association/subset",
    "share/rbbt_commands/benchmark/pthrough",
    "share/rbbt_commands/benchmark/throughput",
    "share/rbbt_commands/benchmark/tsv",
    "share/rbbt_commands/check_bgzf",
    "share/rbbt_commands/color",
    "share/rbbt_commands/conf/web_user/add",
    "share/rbbt_commands/conf/web_user/list",
    "share/rbbt_commands/conf/web_user/remove",
    "share/rbbt_commands/file_server/add",
    "share/rbbt_commands/file_server/list",
    "share/rbbt_commands/file_server/remove",
    "share/rbbt_commands/log",
    "share/rbbt_commands/resource/exists",
    "share/rbbt_commands/resource/find",
    "share/rbbt_commands/resource/get",
    "share/rbbt_commands/resource/produce",
    "share/rbbt_commands/stat/abs",
    "share/rbbt_commands/stat/density",
    "share/rbbt_commands/stat/log",
    "share/rbbt_commands/stat/pvalue.qqplot",
    "share/rbbt_commands/study/maf2study",
    "share/rbbt_commands/study/task",
    "share/rbbt_commands/system/clean",
    "share/rbbt_commands/system/deleted_files",
    "share/rbbt_commands/system/optimize",
    "share/rbbt_commands/system/purge",
    "share/rbbt_commands/system/report",
    "share/rbbt_commands/system/status",
    "share/rbbt_commands/tsv/assemble_pdf_table",
    "share/rbbt_commands/tsv/attach",
    "share/rbbt_commands/tsv/change_id",
    "share/rbbt_commands/tsv/get",
    "share/rbbt_commands/tsv/head",
    "share/rbbt_commands/tsv/info",
    "share/rbbt_commands/tsv/json",
    "share/rbbt_commands/tsv/read",
    "share/rbbt_commands/tsv/slice",
    "share/rbbt_commands/tsv/sort",
    "share/rbbt_commands/tsv/subset",
    "share/rbbt_commands/tsv/unzip",
    "share/rbbt_commands/tsv/values",
    "share/rbbt_commands/watch",
    "share/rbbt_commands/workflow/cmd",
    "share/rbbt_commands/workflow/example",
    "share/rbbt_commands/workflow/info",
    "share/rbbt_commands/workflow/install",
    "share/rbbt_commands/workflow/jobs",
    "share/rbbt_commands/workflow/knowledge_base",
    "share/rbbt_commands/workflow/list",
    "share/rbbt_commands/workflow/monitor",
    "share/rbbt_commands/workflow/prov",
    "share/rbbt_commands/workflow/remote/add",
    "share/rbbt_commands/workflow/remote/list",
    "share/rbbt_commands/workflow/remote/remove",
    "share/rbbt_commands/workflow/server",
    "share/rbbt_commands/workflow/task",
    "share/unicorn.rb"
  ]
  s.homepage = "http://github.com/mikisvaz/rbbt-util"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "Utilities for the Ruby Bioinformatics Toolkit (rbbt)"
  s.test_files = ["test/rbbt/test_workflow.rb", "test/rbbt/resource/test_path.rb", "test/rbbt/util/test_cmd.rb", "test/rbbt/util/simpleopt/test_setup.rb", "test/rbbt/util/simpleopt/test_get.rb", "test/rbbt/util/simpleopt/test_parse.rb", "test/rbbt/util/test_chain_methods.rb", "test/rbbt/util/test_simpleDSL.rb", "test/rbbt/util/test_log.rb", "test/rbbt/util/test_open.rb", "test/rbbt/util/misc/test_lock.rb", "test/rbbt/util/misc/test_bgzf.rb", "test/rbbt/util/misc/test_pipes.rb", "test/rbbt/util/test_concurrency.rb", "test/rbbt/util/test_R.rb", "test/rbbt/util/log/test_progress.rb", "test/rbbt/util/test_colorize.rb", "test/rbbt/util/test_simpleopt.rb", "test/rbbt/util/test_excel2tsv.rb", "test/rbbt/util/test_filecache.rb", "test/rbbt/util/concurrency/test_processes.rb", "test/rbbt/util/concurrency/test_threads.rb", "test/rbbt/util/concurrency/processes/test_socket.rb", "test/rbbt/util/test_semaphore.rb", "test/rbbt/util/test_misc.rb", "test/rbbt/util/test_tmpfile.rb", "test/rbbt/util/R/test_model.rb", "test/rbbt/util/R/test_eval.rb", "test/rbbt/test_packed_index.rb", "test/rbbt/entity/test_identifiers.rb", "test/rbbt/test_association.rb", "test/rbbt/knowledge_base/test_traverse.rb", "test/rbbt/knowledge_base/test_registry.rb", "test/rbbt/knowledge_base/test_entity.rb", "test/rbbt/knowledge_base/test_enrichment.rb", "test/rbbt/knowledge_base/test_syndicate.rb", "test/rbbt/knowledge_base/test_query.rb", "test/rbbt/test_resource.rb", "test/rbbt/test_entity.rb", "test/rbbt/test_knowledge_base.rb", "test/rbbt/annotations/test_util.rb", "test/rbbt/association/test_index.rb", "test/rbbt/association/test_item.rb", "test/rbbt/association/test_open.rb", "test/rbbt/association/test_util.rb", "test/rbbt/association/test_database.rb", "test/rbbt/test_tsv.rb", "test/rbbt/workflow/test_task.rb", "test/rbbt/workflow/test_step.rb", "test/rbbt/workflow/test_doc.rb", "test/rbbt/test_monitor.rb", "test/rbbt/test_persist.rb", "test/rbbt/test_annotations.rb", "test/rbbt/persist/test_tsv.rb", "test/rbbt/persist/tsv/test_lmdb.rb", "test/rbbt/persist/tsv/test_kyotocabinet.rb", "test/rbbt/persist/tsv/test_sharder.rb", "test/rbbt/persist/tsv/test_cdb.rb", "test/rbbt/persist/tsv/test_tokyocabinet.rb", "test/rbbt/persist/tsv/test_leveldb.rb", "test/rbbt/tsv/test_field_index.rb", "test/rbbt/tsv/test_parallel.rb", "test/rbbt/tsv/test_index.rb", "test/rbbt/tsv/test_matrix.rb", "test/rbbt/tsv/test_change_id.rb", "test/rbbt/tsv/test_parser.rb", "test/rbbt/tsv/test_stream.rb", "test/rbbt/tsv/test_util.rb", "test/rbbt/tsv/test_accessor.rb", "test/rbbt/tsv/test_filter.rb", "test/rbbt/tsv/test_attach.rb", "test/rbbt/tsv/test_manipulate.rb", "test/rbbt/tsv/parallel/test_through.rb", "test/rbbt/tsv/parallel/test_traverse.rb", "test/rbbt/test_fix_width_table.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<progress-monitor>, [">= 0"])
      s.add_runtime_dependency(%q<lockfile>, [">= 0"])
      s.add_runtime_dependency(%q<spreadsheet>, [">= 0"])
      s.add_runtime_dependency(%q<highline>, [">= 0"])
      s.add_runtime_dependency(%q<bio-bgzf>, [">= 0"])
      s.add_runtime_dependency(%q<term-ansicolor>, [">= 0"])
      s.add_runtime_dependency(%q<rest-client>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<progress-monitor>, [">= 0"])
      s.add_dependency(%q<lockfile>, [">= 0"])
      s.add_dependency(%q<spreadsheet>, [">= 0"])
      s.add_dependency(%q<highline>, [">= 0"])
      s.add_dependency(%q<bio-bgzf>, [">= 0"])
      s.add_dependency(%q<term-ansicolor>, [">= 0"])
      s.add_dependency(%q<rest-client>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<progress-monitor>, [">= 0"])
    s.add_dependency(%q<lockfile>, [">= 0"])
    s.add_dependency(%q<spreadsheet>, [">= 0"])
    s.add_dependency(%q<highline>, [">= 0"])
    s.add_dependency(%q<bio-bgzf>, [">= 0"])
    s.add_dependency(%q<term-ansicolor>, [">= 0"])
    s.add_dependency(%q<rest-client>, [">= 0"])
  end
end

