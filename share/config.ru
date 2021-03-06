require 'rbbt'
require 'rbbt/resource'
$LOAD_PATH.unshift('lib') unless $LOAD_PATH.include?('lib')

def load_file(file)
  if Array === file
    file.each{|f| load_file f }
  elsif file.exists?
    Log.info("Loading: " << file)
    load file
  end
end

def app_eval(app, file)
  if Array === file
    file.each{|f| app_eval app, f }
  elsif file.exists?
    app.class_eval do
      Log.info("Loading: " << file)
      eval file.read, nil, file
    end
  end
end

#{{{ INIT
load_file Rbbt.etc['app.d/init.rb'].find

$app_dir = FileUtils.pwd
$app_name = app_name = File.basename($app_dir)
$app = app = eval "class #{app_name} < Sinatra::Base; self end"

#{{{ PRE
load_file Rbbt.etc['app.d/pre.rb'].find 

#{{{ WORKFLOWS
app_eval app, Rbbt.etc['app.d/workflows.rb'].find_all

#{{{ REMOTE WORKFLOW TASKS
app_eval app, Rbbt.etc['app.d/remote_workflow_tasks.rb'].find_all

#{{{ BASE
app_eval app, Rbbt.etc['app.d/base.rb'].find

#{{{ RESOURCES
load_file Rbbt.etc['app.d/resources.rb'].find

#{{{ KNOWLEDGEBASE
load_file Rbbt.etc['app.d/knowledge_bases.rb'].find

#{{{ REQUIRES
load_file Rbbt.etc['app.d/requires.rb'].find

#{{{ ENTITIES
load_file Rbbt.etc['app.d/entities.rb'].find

#{{{ ROUTES
app_eval app, Rbbt.etc['app.d/routes.rb'].find_all

#{{{ FINDER
app_eval app, Rbbt.etc['app.d/finder.rb'].find

#{{{ POST
load_file Rbbt.etc['app.d/post.rb'].find_all

#{{{ PRELOAD
load_file Rbbt.etc['app.d/preload.rb'].find_all

#{{{ SINATRA
load_file Rbbt.lib['sinatra.rb'].find_all

#{{{ RUN
$title = app_name
require 'rack'
use Rack::Deflater
run app

