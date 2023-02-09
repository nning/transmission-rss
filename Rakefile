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
    sh '
      touch \
        $(pwd)/transmission-rss.conf \
        $(pwd)/.seen

      docker run \
        -it \
        --net host \
        -v $(pwd)/transmission-rss.conf:/etc/transmission-rss.conf \
        -v $(pwd)/.seen:/home/ruby/.config/transmission/seen \
        transmission-rss
    '
  end

  desc 'Publish docker image'
  task :publish do
    sh "
      set -e
      docker build -t nning2/transmission-rss:#{TransmissionRSS::VERSION} .
      docker tag nning2/transmission-rss:#{TransmissionRSS::VERSION} nning2/transmission-rss:latest
      docker push nning2/transmission-rss:#{TransmissionRSS::VERSION}
      docker push nning2/transmission-rss:latest
    "
  end
end
