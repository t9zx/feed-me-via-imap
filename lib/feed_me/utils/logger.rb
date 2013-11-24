require 'rubygems'
require 'bundler/setup'

require "log4r"

module FeedMe
  module Utils
    class Logger
      # Retrieve a logger for a specific identifier
      # @param [String, Class] identifier retrieve a logger object for the given string/class identifier
      # @return [Object] an object suitable for writing log messages
      def self.get(identifier)
        raise ArgumentError, "identifier must be either a String or a Class" unless identifier.is_a?(String) || identifier.is_a?(Class)

        identifier = identifier.to_s if identifier.is_a?(Class)
        logger = Log4r::Logger.new(identifier)

        return logger
      end
    end
  end
end