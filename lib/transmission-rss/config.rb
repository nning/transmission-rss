require 'singleton'
require 'yaml'

module TransmissionRSS
  # Class handles configuration parameters.
  class Config < Hash
    # This is a singleton class.
    include Singleton

    def initialize(file = nil)
      self.merge!({
        'feeds' => [],
        'update_interval' => 600,
        'add_paused' => false,
        'server' => {
          'host' => 'localhost',
          'port' => 9091
        },
        'login' => nil,
        'log_target' => $stderr,
        'fork' => false,
        'pid_file' => false,
        'privileges' => {},
        'seen_file' => nil
      })

      self.load(file) unless file.nil?
    end

    # Merges a Hash or YAML file (containing a Hash) with itself.
    def load(config)
      case config.class.to_s
      when 'Hash'
        self.merge!(config)
      when 'String'
        self.merge_yaml!(config)
      else
        raise ArgumentError.new('Could not load config.')
      end
    end

    # Merge Config Hash with Hash from YAML file.
    def merge_yaml!(path)
      self.merge!(YAML.load_file(path))
    rescue TypeError
      # If YAML loading fails, .load_file returns `false`.
    end
  end
end
