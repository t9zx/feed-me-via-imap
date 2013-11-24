require 'rubygems'
require 'bundler/setup'

require "uri"

require_relative "../../../lib/feed_me/utils/logger"

module FeedMe
  module Model
    class Feed
      RSS = :rss
      ATOM = :atom

      attr_reader :feed_type, :feed_uri

      # Represents an RSS or ATOM feed
      # @param [Object] feed_type either RSS or ATOM; use constant Feed:RSS or Feed:ATOM
      # @param [URI] feed_uri the URI for accessing the feed
      # @throws [ArgumentError] in case the passed parameters are suitable
      def initialize(feed_type, feed_uri)
        raise ArgumentError, "feed_type must be either RSS or ATOM" unless [RSS, ATOM].include?(feed_type)
        raise ArgumentError, "feed_uri must be an URI" unless feed_uri.is_a?(URI)

        @logger = FeedMe::Utils::Logger.get(self.class)

        @feed_type = feed_type
        @feed_uri = feed_uri

        @logger.debug{"Initialized a new Feed: #{self.to_s}"}
      end

      def to_s
        "Feed: '#{@feed_uri.to_s}' (#{@feed_type})"
      end

    end
  end
end
