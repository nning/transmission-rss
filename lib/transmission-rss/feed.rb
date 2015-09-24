module TransmissionRSS
  class Feed
    attr_reader :url, :regexp, :download_dir

    def initialize(config = {})
      @url = URI.encode(config['url'])
      @regexp = Regexp.new(config['regexp'], Regexp::IGNORECASE) if config['regexp']
      @download_dir = config['download_dir']
    end

    def matches_regexp?(title)
      @regexp.nil? || title =~ @regexp
    end
  end
end
