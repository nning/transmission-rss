require 'etc'
require 'fileutils'
require 'open-uri'
require 'rss'

# Class for aggregating torrent files through RSS feeds.
class TransmissionRSS::Aggregator
  attr_accessor :feeds

  def initialize(feeds = [])
    @feeds = feeds
    @seen = []

    # Initialize log instance.
    @log = Log.instance

    # Declare callback for new items.
    callback(:on_new_item)

    # Generate path for seen torrents store file.
    @seenfile = File.join(
      Etc.getpwuid.dir,
      '/.config/transmission/seen-torrents.conf'
    )

    # Make directories in path if they are not existing.
    FileUtils.mkdir_p(File.dirname(@seenfile))

    # Touch seen torrents store file.
    if(not File.exists?(@seenfile))
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

    while(true)
      feeds.each do |url|
        @log.debug('aggregate ' + url)

        begin
          content = open(url).readlines.join("\n")
          items = RSS::Parser.parse(content, false).items
        rescue
          @log.debug('retrieval error')
          next
        end

        items.each do |item|
          link = item.link
 
          # Item contains no link.
          if(link.nil?)
            next
          end

          # Link is not a String directly.
          if(link.class != String)
            link = link.href
          end

          # The link is not in +@seen+ Array.
          if(not seen?(link))
            on_new_item(link)
            @log.debug('on_new_item event ' + link)

            add_seen(link)
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

  # Method to define callback methods.
  def callback(*names)
    names.each do |name|
      eval <<-EOF
        @#{name} = false
        def #{name}(*args, &block)
          if(block)
            @#{name} = block
          elsif(@#{name})
            @#{name}.call(*args)
          end
        end
      EOF
    end
  end
end
