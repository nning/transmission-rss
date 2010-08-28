$:.unshift( File.dirname( __FILE__ ) )

require( 'libglade2' )

%w( main listbox ).each do |file|
	require( $:.first + '/config-editor/' + file + '.rb' )
end
