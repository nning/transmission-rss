$:.unshift(File.dirname(__FILE__))

module TransmissionRSS
	VERSION = '0.1.14'
end

Dir.glob($:.first + '/**/*.rb').each do |lib|
	require lib
end
