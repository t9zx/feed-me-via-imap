require "yaml"

module FeedMe
  module Config
    class Config

      # Config is used to access configuration information stored in YAML format.
      # @param [IO] config_info the config info as an IO stream
      def initialize(config_info)
        raise ArgumentError, "config_info must respond to .read" unless config_info.respond_to?(:read)
        @config = YAML.load(config_info.read)
      end

      # Returns the value of the requested key from the config. Keys are separated by a "."
      # @param [String] key the key to retrieve
      # @throws [FeedMe::Config::ConfigKeyNotFoundError] in case the key can't be found in the config file
      # @returns [Object] the value retrieved from the config
      def value(key)
        raise ArgumentError, "key must be a String" unless key.is_a?(String)

        keys = key.split(".")
        if keys.size == 0
          raise FeedMe::Config::ConfigKeyNotFoundError, "The key '#{key}' can't be located in the config file"
        end
        temp_key = @config
        keys.each do |k|
          temp_key = temp_key[k]
          if temp_key.nil?
            raise FeedMe::Config::ConfigKeyNotFoundError, "The key '#{key}' can't be located in the config file"
          end
        end

        return temp_key
      end

    end

    class ConfigKeyNotFoundError < StandardError
    end
  end
end