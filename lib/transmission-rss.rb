$:.unshift(File.dirname(__FILE__))

module TransmissionRSS
end

require 'transmission-rss/core_ext/object'

Dir.glob($:.first + '/**/*.rb').each do |lib|
	require lib
end
