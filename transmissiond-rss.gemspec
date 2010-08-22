require 'lib/transmissiond-rss'

Gem::Specification.new do |s|
	s.name = 'transmissiond-rss'

	s.summary = 'Adds torrents from rss feeds to transmissiond web frontend.'
	s.description = "transmissiond-rss is basically a workaround for
		transmissiond's lack of the ability to monitor RSS feeds and
		automatically add enclosed torrent links. Devoted to Ann."

	s.version = Transmissiond_rss::VERSION
	s.author = 'henning mueller'
	s.email = 'henning@orgizm.net'
	s.files = Dir.glob( '{bin,lib}/**/*' ) << 'README.rdoc'
	s.executables = Dir.glob( 'bin/**' ).map { |x| x[4..-1] }
end
