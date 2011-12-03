require 'singleton'
require 'yaml'

# In ruby 1.9.3, Psych is used as YAML engine. Psych maps YAML to a class
# automatically when deserializing, which it does by calling the "new"
# method in that process. This fails with Singleton classes.
YAML::ENGINE.yamler = 'syck'

# Class handles configuration parameters.
class TransmissionRSS::Config < Hash
  # This is a singleton class.
  include Singleton

  # Merges a Hash or YAML file (containing a Hash) with itself.
  def load(config)
    if(config.class == Hash)
      self.merge!(config)
      return
    end

    if(not config.nil?)
      self.merge_yaml!(config)
    end
  end

  # Merge Config Hash with Hash in YAML file.
  def merge_yaml!(path)
    self.merge!(load_file(path))
  end

  # Load YAML file and work around tabs not working for identation.
  def load_file(path)
    YAML.load_stream(
      File.new(path).read.gsub(/\t/, ' ')
    ).documents.first
  end
end
