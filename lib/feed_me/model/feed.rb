require 'rubygems'
require 'bundler/setup'

require "uri"

require_relative "../../../lib/feed_me/utils/logger"

module FeedMe
  module Model
    class Feed
      attr_reader :feed_uri

      # Represents an RSS or ATOM feed
      # @param [URI] feed_uri the URI for accessing the feed
      # @throws [ArgumentError] in case the passed parameters are suitable
      def initialize(feed_uri)
        raise ArgumentError, "feed_uri must be an URI" unless feed_uri.is_a?(URI)

        @logger = FeedMe::Utils::Logger.get(self.class)

        @feed_uri = feed_uri

        @logger.debug{"Initialized a new Feed: #{self.to_s}"}
      end

      def to_s
        "Feed: '#{@feed_uri.to_s}'"
      end

    end
  end
end
