require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task default: :spec

namespace :docker do
  desc 'Build docker image'
  task :build do
    sh 'docker build -t transmission-rss .'
  end

  desc 'Run docker image'
  task :run do
    sh 'docker run -it -v $(pwd)/transmission-rss.conf:/etc/transmission-rss.conf transmission-rss'
  end
end
