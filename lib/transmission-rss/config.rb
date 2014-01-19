require 'singleton'
require 'yaml'

# Class handles configuration parameters.
class TransmissionRSS::Config < Hash
  # This is a singleton class.
  include Singleton

  # Merges a Hash or YAML file (containing a Hash) with itself.
  def load(config)
    if config.class == Hash
      self.merge! config
      return
    end

    unless config.nil?
      self.merge_yaml! config
    end
  end

  # Merge Config Hash with Hash from YAML file.
  def merge_yaml!(path)
    self.merge! YAML.load_file(path)
  end
end
