module TransmissionRSS
  class Feed
    attr_reader :url, :regexp, :config, :validate_cert

    def initialize(config = {})
      @download_paths = {}
      @excludes = {}

      case config
      when Hash
        @config = config

        @url = URI.encode(config['url'] || config.keys.first)

        @download_path = config['download_path']
        @validate_cert = config['validate_cert'].nil? || config['validate_cert']

        matchers = Array(config['regexp']).map do |e|
          e.is_a?(String) ? e : e['matcher']
        end

        @regexp = build_regexp(matchers)

        initialize_download_paths_and_excludes(config['regexp'])
      else
        @config = {}
        @url = config.to_s
      end
    end

    def download_path(title = nil)
      return @download_path if title.nil?

      @download_paths.each do |regexp, path|
        return path if title =~ to_regexp(regexp)
      end

      @download_path
    end

    def matches_regexp?(title)
      @regexp.nil? || !(title =~ @regexp).nil?
    end

    def exclude?(title)
      @excludes.each do |regexp, exclude|
        return title =~ to_regexp(exclude) if title =~ to_regexp(regexp)
      end
      return false
    end

    private

    def build_regexp(matchers)
      matchers = Array(matchers).map { |m| to_regexp(m) }
      matchers.empty? ? nil : Regexp.union(matchers)
    end

    def initialize_download_paths_and_excludes(regexps)
      return unless regexps.is_a?(Array)

      regexps.each do |regexp|
        matcher = regexp['matcher']
        path    = regexp['download_path']
        exclude  = regexp['exclude']

        @download_paths[matcher] = path if matcher && path
        @excludes[matcher] = exclude if matcher && exclude
      end
    end

    def to_regexp(s)
      Regexp.new(s, Regexp::IGNORECASE)
    end
  end
end
