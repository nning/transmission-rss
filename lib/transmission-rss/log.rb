require 'logger'
require 'singleton'

module TransmissionRSS
  # Encapsulates Logger as a singleton class.
  class Log
    include Singleton

    def initialize(target = $stderr)
      old_logger = @logger
      @logger ||= Logger.new(target)

      if old_logger
        @logger.level = old_logger.level
        @logger.formatter = old_logger.formatter
      else
        @logger.level = Logger::DEBUG
        @logger.formatter = proc do |sev, time, _, msg|
          time = time.strftime('%Y-%m-%d %H:%M:%S')
          "#{time} (#{sev.downcase}) #{msg}\n"
        end
      end
    end

    # Change log target (IO or path to a file as String).
    def target=(target)
      initialize(target)
    end

    # If this class misses a method, call it on the encapsulated Logger class.
    def method_missing(sym, *args)
      @logger.send(sym, *args)
    end
  end
end
