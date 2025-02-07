require 'open-uri'
require 'open_uri_redirections'
require 'rss'
require 'openssl'

libdir = File.dirname(__FILE__)
require File.join(libdir, 'log')
require File.join(libdir, 'callback')

module TransmissionRSS
  # Class for aggregating torrent files through RSS feeds.
  class Aggregator
    extend Callback
    callback(:on_new_item) # Declare callback for new items.

    attr_reader :seen

    def initialize(feeds = [], options = {})
      reinitialize!(feeds, options)
    end

    def reinitialize!(feeds = [], options = {})
      seen_file = options[:seen_file]

      # Prepare Array of feeds URLs.
      @feeds = feeds.map { |config| TransmissionRSS::Feed.new(config) }

      # Nothing seen, yet.
      @seen = SeenFile.new(seen_file)

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
            content = fetch(feed)
          rescue StandardError => e
            @log.debug("retrieval error (#{e.class}: #{e.message})")
            next
          end

          # gzip HTTP Content-Encoding is not automatically decompressed in
          # Ruby 1.9.3.
          content = decompress(content) if RUBY_VERSION == '1.9.3'
          begin
            items = parse(content)
          rescue StandardError => e
            @log.debug("parse error (#{e.class}: #{e.message})")
            next
          end

          items.each do |item|
            result = process_link(feed, item)
            next if result.nil?
          end
        end

        if interval == -1
          @log.debug('single run mode, exiting')
          break
        end

        sleep(interval)
      end
    end

    private

    def fetch(feed)
      options = {
        allow_redirections: :safe,
        'User-Agent' => 'transmission-rss'
      }

      unless feed.validate_cert
        @log.debug('aggregate certificate validation: false')
        options[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE
      end

      # open for URIs is obsolete, URI.open does not work in 2.4
      URI.send(:open, feed.url, options).read
    end

    def parse(content)
      RSS::Parser.parse(content, false).items
    end

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

      # Determine whether to use guid or link as seen hash
      seen_value = feed.seen_by_guid ? (item.guid.content rescue item.guid || link).to_s : link

      # The link is not in +@seen+ Array.
      unless @seen.include?(seen_value)
        # Skip if filter defined and not matching.
        unless feed.matches_regexp?(item.title) && !feed.exclude?(item.title)
          @seen.add(seen_value)
          return
        end

        @log.debug('on_new_item event ' + link)

        download_path = feed.download_path(item.title)

        begin
          if feed.delay_time > 0
            @log.debug("sleeping for #{feed.delay_time} seconds...")
            sleep(feed.delay_time)
          end
          on_new_item(link, feed, download_path)
        rescue Client::TooManyRequests
          @log.debug('TooManyRequests: Consider adding delay_time to this feed.')
        rescue Client::Unauthorized, Errno::ECONNREFUSED, Timeout::Error
          @log.debug('not added to seen file ' + link)
        else
          @seen.add(seen_value)
        end
      end

      return link
    end
  end
end
