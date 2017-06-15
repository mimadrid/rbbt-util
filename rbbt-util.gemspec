# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: rbbt-util 5.21.83 ruby lib

Gem::Specification.new do |s|
  s.name = "rbbt-util".freeze
  s.version = "5.21.83"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Miguel Vazquez".freeze]
  s.date = "2017-06-15"
  s.description = "Utilities for handling tsv files, caches, etc".freeze
  s.email = "miguel.vazquez@cnio.es".freeze
  s.executables = ["rbbt_query.rb".freeze, "rbbt_exec.rb".freeze, "rbbt_Rutil.rb".freeze, "rbbt".freeze, "rbbt_dangling_locks.rb".freeze]
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
    "etc/app.d/knowledge_bases.rb",
    "etc/app.d/remote_workflow_tasks.rb",
    "etc/app.d/requires.rb",
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
    "lib/rbbt/rest/client/run.rb",
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
    "lib/rbbt/util/misc/annotated_module.rb",
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
    "lib/rbbt/util/misc/multipart_payload.rb",
    "lib/rbbt/util/misc/objects.rb",
    "lib/rbbt/util/misc/omics.rb",
    "lib/rbbt/util/misc/options.rb",
    "lib/rbbt/util/misc/pipes.rb",
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
    "lib/rbbt/util/tc_cache.rb",
    "lib/rbbt/util/tmpfile.rb",
    "lib/rbbt/workflow.rb",
    "lib/rbbt/workflow/accessor.rb",
    "lib/rbbt/workflow/annotate.rb",
    "lib/rbbt/workflow/definition.rb",
    "lib/rbbt/workflow/doc.rb",
    "lib/rbbt/workflow/examples.rb",
    "lib/rbbt/workflow/soap.rb",
    "lib/rbbt/workflow/step.rb",
    "lib/rbbt/workflow/step/dependencies.rb",
    "lib/rbbt/workflow/step/run.rb",
    "lib/rbbt/workflow/task.rb",
    "lib/rbbt/workflow/usage.rb",
    "share/Rlib/plot.R",
    "share/Rlib/svg.R",
    "share/Rlib/util.R",
    "share/color/color_names",
    "share/color/diverging_colors.hex",
    "share/config.ru",
    "share/install/software/HTSLIB",
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
    "share/rbbt_commands/rsync",
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
    "share/rbbt_commands/tsv/collapse",
    "share/rbbt_commands/tsv/get",
    "share/rbbt_commands/tsv/head",
    "share/rbbt_commands/tsv/info",
    "share/rbbt_commands/tsv/json",
    "share/rbbt_commands/tsv/query",
    "share/rbbt_commands/tsv/read",
    "share/rbbt_commands/tsv/read_excel",
    "share/rbbt_commands/tsv/slice",
    "share/rbbt_commands/tsv/sort",
    "share/rbbt_commands/tsv/subset",
    "share/rbbt_commands/tsv/transpose",
    "share/rbbt_commands/tsv/unzip",
    "share/rbbt_commands/tsv/values",
    "share/rbbt_commands/tsv/write_excel",
    "share/rbbt_commands/tsv/zip",
    "share/rbbt_commands/watch",
    "share/rbbt_commands/workflow/cmd",
    "share/rbbt_commands/workflow/example",
    "share/rbbt_commands/workflow/info",
    "share/rbbt_commands/workflow/init",
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
    "share/unicorn.rb",
    "share/workflow_config.ru"
  ]
  s.homepage = "http://github.com/mikisvaz/rbbt-util".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.6".freeze
  s.summary = "Utilities for the Ruby Bioinformatics Toolkit (rbbt)".freeze
  s.test_files = ["test/test_helper.rb".freeze, "test/rbbt/resource/test_path.rb".freeze, "test/rbbt/association/test_item.rb".freeze, "test/rbbt/association/test_database.rb".freeze, "test/rbbt/association/test_open.rb".freeze, "test/rbbt/association/test_index.rb".freeze, "test/rbbt/association/test_util.rb".freeze, "test/rbbt/util/test_concurrency.rb".freeze, "test/rbbt/util/test_log.rb".freeze, "test/rbbt/util/test_chain_methods.rb".freeze, "test/rbbt/util/test_simpleopt.rb".freeze, "test/rbbt/util/simpleopt/test_parse.rb".freeze, "test/rbbt/util/simpleopt/test_get.rb".freeze, "test/rbbt/util/simpleopt/test_setup.rb".freeze, "test/rbbt/util/test_cmd.rb".freeze, "test/rbbt/util/test_semaphore.rb".freeze, "test/rbbt/util/concurrency/test_threads.rb".freeze, "test/rbbt/util/concurrency/processes/test_socket.rb".freeze, "test/rbbt/util/concurrency/test_processes.rb".freeze, "test/rbbt/util/test_tmpfile.rb".freeze, "test/rbbt/util/test_open.rb".freeze, "test/rbbt/util/test_filecache.rb".freeze, "test/rbbt/util/R/test_eval.rb".freeze, "test/rbbt/util/R/test_model.rb".freeze, "test/rbbt/util/test_simpleDSL.rb".freeze, "test/rbbt/util/log/test_progress.rb".freeze, "test/rbbt/util/test_colorize.rb".freeze, "test/rbbt/util/test_R.rb".freeze, "test/rbbt/util/misc/test_lock.rb".freeze, "test/rbbt/util/misc/test_pipes.rb".freeze, "test/rbbt/util/misc/test_bgzf.rb".freeze, "test/rbbt/util/misc/test_omics.rb".freeze, "test/rbbt/util/misc/test_multipart_payload.rb".freeze, "test/rbbt/util/test_excel2tsv.rb".freeze, "test/rbbt/util/test_misc.rb".freeze, "test/rbbt/test_entity.rb".freeze, "test/rbbt/workflow/step/test_dependencies.rb".freeze, "test/rbbt/workflow/test_doc.rb".freeze, "test/rbbt/workflow/test_step.rb".freeze, "test/rbbt/workflow/test_task.rb".freeze, "test/rbbt/test_association.rb".freeze, "test/rbbt/test_knowledge_base.rb".freeze, "test/rbbt/tsv/parallel/test_traverse.rb".freeze, "test/rbbt/tsv/parallel/test_through.rb".freeze, "test/rbbt/tsv/test_parallel.rb".freeze, "test/rbbt/tsv/test_excel.rb".freeze, "test/rbbt/tsv/test_accessor.rb".freeze, "test/rbbt/tsv/test_change_id.rb".freeze, "test/rbbt/tsv/test_stream.rb".freeze, "test/rbbt/tsv/test_filter.rb".freeze, "test/rbbt/tsv/test_matrix.rb".freeze, "test/rbbt/tsv/test_attach.rb".freeze, "test/rbbt/tsv/test_manipulate.rb".freeze, "test/rbbt/tsv/test_field_index.rb".freeze, "test/rbbt/tsv/test_index.rb".freeze, "test/rbbt/tsv/test_util.rb".freeze, "test/rbbt/tsv/test_parser.rb".freeze, "test/rbbt/test_packed_index.rb".freeze, "test/rbbt/test_persist.rb".freeze, "test/rbbt/test_fix_width_table.rb".freeze, "test/rbbt/knowledge_base/test_traverse.rb".freeze, "test/rbbt/knowledge_base/test_entity.rb".freeze, "test/rbbt/knowledge_base/test_query.rb".freeze, "test/rbbt/knowledge_base/test_enrichment.rb".freeze, "test/rbbt/knowledge_base/test_syndicate.rb".freeze, "test/rbbt/knowledge_base/test_registry.rb".freeze, "test/rbbt/entity/test_identifiers.rb".freeze, "test/rbbt/test_monitor.rb".freeze, "test/rbbt/test_workflow.rb".freeze, "test/rbbt/test_annotations.rb".freeze, "test/rbbt/annotations/test_util.rb".freeze, "test/rbbt/test_resource.rb".freeze, "test/rbbt/persist/tsv/test_tokyocabinet.rb".freeze, "test/rbbt/persist/tsv/test_kyotocabinet.rb".freeze, "test/rbbt/persist/tsv/test_lmdb.rb".freeze, "test/rbbt/persist/tsv/test_leveldb.rb".freeze, "test/rbbt/persist/tsv/test_cdb.rb".freeze, "test/rbbt/persist/tsv/test_sharder.rb".freeze, "test/rbbt/persist/test_tsv.rb".freeze, "test/rbbt/test_tsv.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<progress-monitor>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<lockfile>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<spreadsheet>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rubyXL>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<highline>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<bio-bgzf>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<term-ansicolor>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rest-client>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<to_regexp>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<nakayoshi_fork>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<progress-monitor>.freeze, [">= 0"])
      s.add_dependency(%q<lockfile>.freeze, [">= 0"])
      s.add_dependency(%q<spreadsheet>.freeze, [">= 0"])
      s.add_dependency(%q<rubyXL>.freeze, [">= 0"])
      s.add_dependency(%q<highline>.freeze, [">= 0"])
      s.add_dependency(%q<bio-bgzf>.freeze, [">= 0"])
      s.add_dependency(%q<term-ansicolor>.freeze, [">= 0"])
      s.add_dependency(%q<rest-client>.freeze, [">= 0"])
      s.add_dependency(%q<to_regexp>.freeze, [">= 0"])
      s.add_dependency(%q<nakayoshi_fork>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<progress-monitor>.freeze, [">= 0"])
    s.add_dependency(%q<lockfile>.freeze, [">= 0"])
    s.add_dependency(%q<spreadsheet>.freeze, [">= 0"])
    s.add_dependency(%q<rubyXL>.freeze, [">= 0"])
    s.add_dependency(%q<highline>.freeze, [">= 0"])
    s.add_dependency(%q<bio-bgzf>.freeze, [">= 0"])
    s.add_dependency(%q<term-ansicolor>.freeze, [">= 0"])
    s.add_dependency(%q<rest-client>.freeze, [">= 0"])
    s.add_dependency(%q<to_regexp>.freeze, [">= 0"])
    s.add_dependency(%q<nakayoshi_fork>.freeze, [">= 0"])
  end
end

