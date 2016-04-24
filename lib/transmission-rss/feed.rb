module TransmissionRSS
  class Feed
    attr_reader :url, :regexp, :download_path

    def initialize(config = {})
      case config
      when Hash
        @url = URI.encode(config['url'] || config.keys.first)
        @regexp = build_regexp(config['regexp'])
        @download_path = config['download_path']
      else
        @url = config.to_s
      end
    end

    def matches_regexp?(title)
      @regexp.nil? || !(title =~ @regexp).nil?
    end

    private

    def build_regexp(matchers)
      matchers = Array(matchers).map { |m| Regexp.new(m, Regexp::IGNORECASE) }
      matchers.empty? ? nil : Regexp.union(matchers)
    end
  end
end
