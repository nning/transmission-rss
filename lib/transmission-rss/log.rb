require 'logger'
require 'singleton'

module TransmissionRSS
  # Encapsulates Logger as a singleton class.
  class Log
    include Singleton

    def initialize(target = $stderr, level = :debug)
      @target = target
      @level = level

      @logger = Logger.new(target)
      @logger.level = to_level_const(level)
      @logger.formatter = proc do |sev, time, _, msg|
        time = time.strftime('%Y-%m-%d %H:%M:%S')
        "#{time} (#{sev.downcase}) #{msg}\n"
      end
    end

    # Change log target (IO, path to a file as String, or Symbol for IO
    # constant).
    def target=(target)
      if target.is_a? Symbol
        target = Object.const_get(target.to_s.upcase)
      end

      initialize(target, @level)
    end

    # Change log level (String or Symbol)
    def level=(level)
      initialize(@target, level)
    end

    # If this class misses a method, call it on the encapsulated Logger class.
    def method_missing(sym, *args)
      @logger.send(sym, *args)
    end

    private

    def to_level_const(level)
      Object.const_get('Logger::' + level.to_s.upcase)
    end
  end
end
