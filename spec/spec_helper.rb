require 'coveralls'
require 'vcr'

basedir = File.join(File.dirname(__FILE__), '..')
require File.join(basedir, 'lib', 'transmission-rss')

include TransmissionRSS

def tmp_path(file)
  File.join(Dir.tmpdir, 'rspec', file.to_s)
end

Coveralls.wear!

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
end
