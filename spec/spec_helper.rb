basedir = File.join(File.dirname(__FILE__), '..')

require File.join(basedir, 'lib', 'transmission-rss')

include TransmissionRSS

Log.instance.target = File.open(File.join(basedir, 'log', 'test.log'), 'a')
