$:.unshift( File.dirname( __FILE__ ) )

module TransmissionRSS
	VERSION = '0.1.4'
end

dir = 'transmission-rss'

blacklist = %w(
	config-editor
)

blacklist.map! do |name|
	$:.first + '/' + dir + '/' + name + '.rb'
end

( Dir.glob( $:.first + '/' + dir + '/*.rb' ) - blacklist ).each do |lib|
	require( lib )
end
