worker_processes 4
timeout 30

@app_path = Dir.pwd
@port = "2887"

#socket_file = "#{@app_path}/tmp/sockets/unicorn.sock"
#FileUtils.mkdir_p File.dirname(socket_file)
#listen socket_file, :backlog => 64

pid_file = "#{@app_path}/tmp/pids/unicorn.pid"
FileUtils.mkdir_p File.dirname(pid_file)
pid pid_file
