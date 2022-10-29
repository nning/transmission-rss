module TransmissionRSS
  class Feed
    attr_reader :url, :regexp, :config, :validate_cert, :seen_by_guid

    def initialize(config = {})
      @download_paths = {}

      case config
      when Hash
        @config = config

        @url = URI.escape(URI.unescape(config['url'] || config.keys.first))

        @download_path = config['download_path']

        matchers = Array(config['regexp']).map do |e|
          e.is_a?(String) ? e : e['matcher']
        end

        @regexp = build_regexp(matchers)

        initialize_download_paths(config['regexp'])
      else
        @config = {}
        @url = config.to_s
      end

      @validate_cert = @config['validate_cert'].nil? || !!@config['validate_cert']
      @seen_by_guid = !!@config['seen_by_guid']
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

    private

    def build_regexp(matchers)
      matchers = Array(matchers).map { |m| to_regexp(m) }
      matchers.empty? ? nil : Regexp.union(matchers)
    end

    def initialize_download_paths(regexps)
      return unless regexps.is_a?(Array)

      regexps.each do |regexp|
        matcher = regexp['matcher']
        path    = regexp['download_path']

        @download_paths[matcher] = path if matcher && path
      end
    end

    def to_regexp(s)
      Regexp.new(s, Regexp::IGNORECASE)
    end
  end
end
