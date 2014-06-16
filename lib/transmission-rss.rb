$:.unshift(File.dirname(__FILE__))

module TransmissionRSS
end

Dir.glob($:.first + '/**/*.rb').each do |lib|
	require lib
end
