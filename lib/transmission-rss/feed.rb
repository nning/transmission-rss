module TransmissionRSS
  class Feed
    attr_reader :url, :regexp, :config, :validate_cert, :matcher_configs

    def initialize(config = {})
      @matcher_configs = {}

      matchers = Array.new

      case config
      when Hash
        @config = config
        @url = URI.escape(config['url'] || config.keys.first)
        @validate_cert = config['validate_cert'].nil? || config['validate_cert']
        matchers = Array(config['regexp']).map do |e|
          e.is_a?(String) ? {'matcher' => e} : e
        end
      else
        @config = {}
        @url = config.to_s
      end

      matchers.push({'matcher' => '(.*?)'}) if matchers.empty?

      @regexp = build_regexp(matchers)

      initialize_matcher_config(matchers)
    end

    def get_config(title = nil)
      return matcher_configs[:'(.*?)'] if title.nil?

      matcher_configs.each do |regexp, config|
        return config if title =~ to_regexp(regexp)
      end

      matcher_configs['(.*?)']
    end

    def matches_regexp?(title)
      @regexp.nil? || !(title =~ @regexp).nil?
    end

    private

    def build_regexp(matchers)
      matchers = Array(matchers).map { |m| to_regexp(m['matcher']) }
      matchers.empty? ? nil : Regexp.union(matchers)
    end

    def initialize_matcher_config(regexps)
      return unless regexps.is_a?(Array)

      regexps.each do |regexp|
        matcher = regexp['matcher']
        if matcher
          matcher_configs[matcher] = config.merge(regexp)
          matcher_configs[matcher].delete('url')
          matcher_configs[matcher].delete('regexp')
          matcher_configs[matcher].delete('matcher')
          matcher_configs[matcher].transform_keys!(&:to_sym)
        end
      end
    end

    def to_regexp(s)
      Regexp.new(s, Regexp::IGNORECASE)
    end
  end
end
