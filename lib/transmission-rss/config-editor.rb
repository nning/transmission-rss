$:.unshift( File.dirname( __FILE__ ) )

require( 'libglade2' )

dir = 'config-editor'

blacklist = %w(
	listbox-original
)

blacklist.map! do |name|
	$:.first + '/' + dir + '/' + name + '.rb'
end

( Dir.glob( $:.first + '/' + dir + '/*.rb' ) - blacklist ).each do |lib|
	require( lib )
end
