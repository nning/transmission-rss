$:.unshift( File.dirname( __FILE__ ) )

require( 'libglade2' )

Dir.glob( $:.first + '/config-editor/*.rb' ).each do |file|
	require( file )
end
