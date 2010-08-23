$:.unshift( File.dirname( __FILE__ ) )

module TransmissionRSS
	VERSION = '0.0.9'
end

Dir.glob( $:.first + '/**/*.rb' ).each do |file|
	require( file )
end
