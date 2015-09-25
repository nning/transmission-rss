require 'etc'
require 'fileutils'
require 'open-uri'
require 'open_uri_redirections'
require 'rss'

libdir = File.dirname(__FILE__)
require File.join(libdir, 'log')
require File.join(libdir, 'callback')

module TransmissionRSS
  # Class for aggregating torrent files through RSS feeds.
  class Aggregator
    extend Callback
    callback(:on_new_item) # Declare callback for new items.

    def initialize(feeds = [], options = {})
      seen_file = options[:seen_file]

      # Prepare Array of feeds URLs.
      @feeds = feeds.map { |config| TransmissionRSS::Feed.new(config) }

      # Nothing seen, yet.
      @seen = []

      # Initialize log instance.
      @log = Log.instance

      # Generate path for seen torrents store file.
      @seenfile = seen_file || File.join(Etc.getpwuid.dir,
        '/.config/transmission/seen-torrents.conf')

      # Make directories in path if they are not existing.
      FileUtils.mkdir_p(File.dirname(@seenfile))

      # Touch seen torrents store file.
      unless File.exists?(@seenfile)
        FileUtils.touch(@seenfile)
      end

      # Open file, read torrent URLs and add to +@seen+.
      open(@seenfile).readlines.each do |line|
        @seen.push(line.chomp)
      end

      # Log number of +@seen+ URIs.
      @log.debug(@seen.size.to_s + ' uris from seenfile')
    end

    # Get file enclosures from all feeds items and call on_new_item callback
    # with torrent file URL as argument.
    def run(interval = 600)
      @log.debug('aggregator start')

      while true
        @feeds.each do |feed|
          @log.debug('aggregate ' + feed.url)

          begin
            content = open(feed.url, allow_redirections: :safe).read
          rescue Exception => e
            @log.debug("retrieval error (#{e.class}: #{e.message})")
            next
          end

          # gzip HTTP Content-Encoding is not automatically decompressed in
          # Ruby 1.9.3.
          content = decompress(content) if RUBY_VERSION == '1.9.3'
          begin
            items = RSS::Parser.parse(content, false).items
          rescue Exception => e
            @log.debug("parse error (#{e.class}: #{e.message})")
            next
          end

          items.each do |item|
            link = item.enclosure.url rescue item.link

            # Item contains no link.
            next if link.nil?

            # Link is not a String directly.
            link = link.href if link.class != String

            # The link is not in +@seen+ Array.
            unless seen?(link)
              # Skip if filter defined and not matching.
              unless feed.matches_regexp?(item.title)
                add_seen(link)
                next
              end

              @log.debug('on_new_item event ' + link)

              begin
                on_new_item(link, feed)
              rescue Client::Unauthorized, Errno::ECONNREFUSED, Timeout::Error
                # Do not add to seen file.
              else
                add_seen(link)
              end
            end
          end
        end

        sleep(interval)
      end
    end

    # To add a link into the list of seen links.
    def add_seen(link)
      @seen.push(link)

      File.open(@seenfile, 'w') do |file|
        file.write(@seen.join("\n"))
      end
    end

    # To test if a link is in the list of seen links.
    def seen?(link)
      @seen.include?(link)
    end

    private

    def decompress(string)
      Zlib::GzipReader.new(StringIO.new(string)).read
    rescue Zlib::GzipFile::Error, Zlib::Error
      string
    end
  end
end
