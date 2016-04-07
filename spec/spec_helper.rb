require 'coveralls'
require 'vcr'

basedir = File.join(File.dirname(__FILE__), '..')
require File.join(basedir, 'lib', 'transmission-rss')

include TransmissionRSS

Coveralls.wear!

Log.instance.target = File.open(File.join(basedir, 'log', 'test.log'), 'a')

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
end
