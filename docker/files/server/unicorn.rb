working_directory "/var/lib/cyclid"
pid "/var/run/unicorn.cyclid-api.pid"

stderr_path "/var/log/cyclid/unicorn.cyclid-api.log"
stdout_path "/var/log/cyclid/unicorn.cyclid-api.log"

listen 8361

worker_processes 4
timeout 10
