require 'digest'
require 'etc'
require 'fileutils'
require 'forwardable'

module TransmissionRSS
  # Persist seen torrent URLs
  class SeenFile
    extend ::Forwardable

    DEFAULT_LEGACY_PATH =
      File.join(Etc.getpwuid.dir, '.config/transmission/seen-torrents.conf')

    DEFAULT_PATH =
      File.join(Etc.getpwuid.dir, '.config/transmission/seen')
    
    def_delegators :@seen, :size, :to_a

    def initialize(path = nil, legacy_path = nil)
      @legacy_path = legacy_path || DEFAULT_LEGACY_PATH
      @path        = path || DEFAULT_PATH

      initialize_path!
      migrate!

      @seen = Set.new(file_to_array(@path))
    end

    def add(url)
      hash = digest(url)
      
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

    def include?(url)
      @seen.include?(digest(url))
    end

    private

    def digest(s)
      Digest::SHA256.hexdigest(s)
    end

    def file_to_array(path)
      open(path, 'r').readlines.map(&:chomp)
    end

    def initialize_path!
      return if File.exist?(@path)

      FileUtils.mkdir_p(File.dirname(@path))
      FileUtils.touch(@path)
    end

    def migrate!
      return unless File.exist?(@legacy_path)

      legacy_seen = file_to_array(@legacy_path)
      hashes = legacy_seen.map { |url| digest(url) }

      open(@path, 'w') do |f|
        f.write(hashes.join("\n"))
        f.write("\n")
      end

      FileUtils.rm_f(@legacy_path)
    end
  end
end
