$:.unshift(File.dirname(__FILE__))

module TransmissionRSS
end

require 'transmission-rss/core_ext/Array'
require 'transmission-rss/core_ext/Object'
require 'transmission-rss/uri_helper'

Dir.glob($:.first + '/**/*.rb').each do |lib|
	require lib
end
