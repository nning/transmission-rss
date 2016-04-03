require 'etc'

module TransmissionRSS
  # Persist seen torrent URLs
  class SeenFile
    DEFAULT_LEGACY_PATH =
      File.join(Etc.getpwuid.dir, '.config/transmission/seen-torrents.conf')

    DEFAULT_PATH =
      File.join(Etc.getpwuid.dir, '.config/transmission/seen')

    def initialize(path = nil, legacy_path = nil)
      @legacy_path = legacy_path || DEFAULT_LEGACY_PATH
      @path        = path || DEFAULT_PATH

      @seen = Set.new

      if !File.exist?(@path)
        initialize_legacy_path!

        # Open file, read torrent URLs and add to +@seen+.
        @seen = Set.new(open(@legacy_path).readlines.map(&:chomp))
      end
    end

    def add(url)
      @seen << url

      open(@legacy_path, 'a') do |f|
        f.write(url + "\n")
      end
    end

    def clear!
      @seen.clear
    end

    def include?(url)
      @seen.include?(url)
    end

    def size
      @seen.size
    end

    def to_a
      @seen.to_a
    end

    private

    def initialize_legacy_path!
      return if File.exist?(@legacy_path)

      # Make directories in path if they are not existing.
      FileUtils.mkdir_p(File.dirname(@legacy_path))

      # Touch seen torrents store file.
      FileUtils.touch(@legacy_path)
    end
  end
end
