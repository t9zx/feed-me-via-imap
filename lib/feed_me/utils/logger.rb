require 'rubygems'
require 'bundler/setup'

require "log4r"
require "log4r/configurator"

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

# as files are loaded only once, we should be safe here and not configure over and over again
Log4r::Configurator.load_xml_file("#{File.dirname(__FILE__)}/../../../conf/log4r.xml")
puts "Logger configuration loaded"