$: << File.dirname(__FILE__)
require 'lib/transmission-rss/version'

Gem::Specification.new do |s|
  s.name = 'transmission-rss'

  s.summary = 'Adds torrents from rss feeds to transmission web frontend.'
  s.description = "transmission-rss is basically a workaround for
    transmission's lack of the ability to monitor RSS feeds and
    automatically add enclosed torrent links. Devoted to Ann."

  s.homepage = 'https://rubygems.org/gems/transmission-rss'
  s.version = TransmissionRSS::VERSION
  s.licenses = ['GPL-3.0']
  s.author = 'henning mueller'
  s.email = 'henning@orgizm.net'
  s.files = Dir.glob('{bin,lib}/**/*').push 'README.md', 'transmission-rss.conf.example'
  s.executables = Dir.glob('bin/**').map { |x| x[4..-1] }

  s.required_ruby_version = '>= 2.1'

  s.add_dependency 'rss', '~> 0.2', '>= 0.2.9'
  s.add_dependency 'open_uri_redirections', '~> 0.2', '>= 0.2.1'
  s.add_dependency 'rb-inotify', '~> 0.9', '>= 0.9.10'
end
