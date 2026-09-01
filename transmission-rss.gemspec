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

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'rss', '~> 0.3'
  s.add_dependency 'open_uri_redirections', '~> 0.2', '>= 0.2.1'
  s.add_dependency 'rb-inotify', '~> 0.10'

  # Standard library gems extracted in Ruby 3.x
  s.add_dependency 'base64', '~> 0.2'
  s.add_dependency 'digest', '~> 3.1'
  s.add_dependency 'etc', '~> 1.4'
  s.add_dependency 'fileutils', '~> 1.7'
  s.add_dependency 'getoptlong', '~> 0.2'
  s.add_dependency 'json', '~> 2.7'
  s.add_dependency 'logger', '~> 1.6'
end
