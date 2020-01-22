module URI
  def self.escape(*arg)
    URI::DEFAULT_PARSER.escape(*arg)
  end

  def self.unescape(*arg)
    URI::DEFAULT_PARSER.unescape(*arg)
  end
end
