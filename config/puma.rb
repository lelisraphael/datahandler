workers Integer(ENV['WEB_CONCURRENCY'] || 8)
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 20)
threads threads_count, threads_count

preload_app!

rackup DefaultRackup
port ENV['PORT'] || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  ActiveRecord::Base.establish_connection
end
