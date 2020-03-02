require 'digest'
require 'etc'
require 'fileutils'
require 'forwardable'

module TransmissionRSS
  # Persist seen torrent URLs
  class SeenFile
    extend ::Forwardable

    def_delegators :@seen, :size, :to_a

    def initialize(path = nil)
      @path = path || default_path
      initialize_path!(@path)

      @seen = Set.new(file_to_array(@path))
    end

    def add(feed, url)
      hash = to_entry(feed, url)

      return if @seen.include?(hash)

      @seen << hash

      open(@path, 'a') do |f|
        f.write(hash + "\n")
      end
    end

    def clear!
      @seen.clear
      open(@path, 'w') {}
    end

    def include?(feed, url)
      @seen.include?(to_entry(feed, url))
    end

    private

    def default_path
      File.join(Etc.getpwuid.dir, '.config/transmission/seen')
    end

    def digest(s)
      Digest::SHA256.hexdigest(s)
    end

    def to_entry(feed, url)
      digest(serialize(feed, url))
    end

    def file_to_array(path)
      open(path, 'r').readlines.map(&:chomp)
    end

    def initialize_path!(path)
      return if File.exist?(path)

      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(path)
    end

    def serialize(feed, url)
      o = { feed_url: feed.url, torrent_url: url }
      YAML.dump(o)
    end
  end
end
