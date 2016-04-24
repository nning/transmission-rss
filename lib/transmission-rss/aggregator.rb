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
      @seen = SeenFile.new(nil, seen_file)

      # Initialize log instance.
      @log = Log.instance

      # Log number of +@seen+ URIs.
      @log.debug(@seen.size.to_s + ' uris from seenfile')
    end

    # Get file enclosures from all feeds items and call on_new_item callback
    # with torrent file URL as argument.
    def run(interval = 600)
      @log.debug('aggregator start')

      loop do
        @feeds.each do |feed|
          @log.debug('aggregate ' + feed.url)

          begin
            content = open(feed.url, allow_redirections: :safe).read
          rescue StandardError => e
            @log.debug("retrieval error (#{e.class}: #{e.message})")
            next
          end

          # gzip HTTP Content-Encoding is not automatically decompressed in
          # Ruby 1.9.3.
          content = decompress(content) if RUBY_VERSION == '1.9.3'
          begin
            items = RSS::Parser.parse(content, false).items
          rescue StandardError => e
            @log.debug("parse error (#{e.class}: #{e.message})")
            next
          end

          items.each do |item|
            result = process_link(feed, item)
            next if result.nil?
          end
        end

        sleep(interval)
      end
    end

    private

    def decompress(string)
      Zlib::GzipReader.new(StringIO.new(string)).read
    rescue Zlib::GzipFile::Error, Zlib::Error
      string
    end

    def process_link(feed, item)
      link = item.enclosure.url rescue item.link

      # Item contains no link.
      return if link.nil?

      # Link is not a String directly.
      link = link.href if link.class != String

      # The link is not in +@seen+ Array.
      unless @seen.include?(link)
        # Skip if filter defined and not matching.
        unless feed.matches_regexp?(item.title)
          @seen.add(link)
          return
        end

        @log.debug('on_new_item event ' + link)

        download_path = feed.download_path(item.title)

        begin
          on_new_item(link, feed, download_path)
        rescue Client::Unauthorized, Errno::ECONNREFUSED, Timeout::Error
          @log.debug('not added to seen file ' + link)
        else
          @seen.add(link)
        end
      end

      return link
    end
  end
end
