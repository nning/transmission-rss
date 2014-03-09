require 'logger'
require 'singleton'

module TransmissionRSS
  # Encapsulates Logger as a singleton class.
  class Log
    include Singleton

    # Change log target (IO or path to a file as String).
    def target=(target)
      old_logger = @logger
      @logger = Logger.new target

      if old_logger
        @logger.level = old_logger.level
        @logger.formatter = old_logger.formatter
      end
    end

    # If this class misses a method, call it on the encapsulated Logger class.
    def method_missing(sym, *args)
      @logger ||= Logger.new $stderr
      @logger.send sym, *args
    end
  end
end
