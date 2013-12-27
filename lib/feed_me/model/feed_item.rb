require 'rubygems'
require 'bundler/setup'

require 'date'
require "uri"

module FeedMe
  module Model
    class FeedItem

      attr_reader :title, :body, :uri, :msg_id, :ts

      # Represents an item from a feed
      # @param [FeedMe::Model::Feed] feed the feed to which this item belongs
      # @param [String] title the title of the feed item
      # @param [String] body the body of the feed item
      # @param [URI] uri the URI where the complete item is accessible
      # @param [String] msg_id a unique ID (for the this feed) which uniquely identified this item
      # @param [DateTime] ts the time stamp/data/time when this article was created
      # @throws [ArgumentError] in case the passed parameters are suitable
      def initialize(feed, title, body, uri, msg_id, ts)
        raise ArgumentError, "feed must be Feed instance" unless feed.is_a?(FeedMe::Model::Feed)
        raise ArgumentError, "title must be a String" unless title.is_a?(String)
        raise ArgumentError, "body must be a String" unless body.is_a?(String)
        raise ArgumentError, "uri must be a URI" unless uri.is_a?(URI)
        raise ArgumentError, "msg_id must be a String" unless msg_id.is_a?(String)
        raise ArgumentError, "msg_id must be a Time" unless ts.is_a?(DateTime)

        @logger = FeedMe::Utils::Logger.get(self.class)

        @feed = feed
        @title = title
        @body = body
        @uri = uri
        @msg_id = msg_id
        @ts = ts

        @feed.add_feed_item(self)

        @logger.debug{"Created new FeedItem: #{self.to_s}"}
      end


      def to_s
        "FeedItem: #{@title[0, 20]} at #{@uri.to_s[0, 20]} (#{@feed.to_s})"
      end
    end
  end
end
