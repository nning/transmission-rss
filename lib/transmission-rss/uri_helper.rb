require 'uri'

module TransmissionRSS
  module URIHelper
    # Normalizes a URL by percent-encoding characters that are invalid in a URI
    # while preserving existing valid percent-encoded sequences (e.g. %20, %2F).
    def normalize_url(url)
      url.gsub(/[^\w\-.~:\/?\[\]@!$&'()*+,;=%]|%(?![0-9A-Fa-f]{2})/) do |c|
        URI::DEFAULT_PARSER.escape(c)
      end
    end

    private :normalize_url
  end
end
