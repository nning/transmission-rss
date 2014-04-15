$:.unshift(File.dirname(__FILE__))

module TransmissionRSS
	VERSION = '0.1.16'
end

Dir.glob($:.first + '/**/*.rb').each do |lib|
	require lib
end
