require 'etc'

module TransmissionRSS
  # Persist seen torrent URLs
  class SeenFile
    extend Forwardable

    DEFAULT_LEGACY_PATH =
      File.join(Etc.getpwuid.dir, '.config/transmission/seen-torrents.conf')

    DEFAULT_PATH =
      File.join(Etc.getpwuid.dir, '.config/transmission/seen')
    
    def_delegator  :@seen, :clear, :clear!
    def_delegators :@seen, :include?, :size, :to_a

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
