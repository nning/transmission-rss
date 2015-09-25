module TransmissionRSS
  class Feed
    attr_reader :url, :regexp, :download_path

    def initialize(config = {})
      if config.is_a? String
        @url = config
      elsif config.is_a? Hash
        @url = URI.encode(config['url'] || config.keys.first)
        @regexp = Regexp.new(config['regexp'], Regexp::IGNORECASE) if config['regexp']
        @download_path = config['download_path']
      end
    end

    def matches_regexp?(title)
      @regexp.nil? || !(title =~ @regexp).nil?
    end
  end
end
