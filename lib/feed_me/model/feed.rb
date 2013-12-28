require 'rubygems'
require 'bundler/setup'

require "uri"

require_relative "feed_item"
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
        @feed_items = []

        @logger.debug{"Initialized a new Feed: #{self.to_s}"}
      end

      # Adds a FeedItem to this feed; in case this very FeedItem was already added, it's won't be added again
      # @param [FeedMe::Model::FeedItem] feed_item the FeedItem which belongs to this feed
      # @throws [ArgumentError] in case a wrong param is passed
      def add_feed_item(feed_item)
        raise ArgumentError, "feed_item must be not nil and of type FeedItem (got: '#{feed_item.class.to_s}')" unless !feed_item.nil? && feed_item.instance_of?(FeedMe::Model::FeedItem)

        @feed_items << feed_item unless @feed_items.include?(feed_item)

        return nil
      end

      # Returns a (shallow) dup of the FeedItems stored; thus, you can't modify remove/reorder items associated with this feed
      # @return [Array<FeedMe::Model::FeedItem]
      def feed_items
        return @feed_items.dup
      end

      def to_s
        "Feed: '#{@feed_uri.to_s}' Items: #{@feed_items.count}"
      end

    end
  end
end
