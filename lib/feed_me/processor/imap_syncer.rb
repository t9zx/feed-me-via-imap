require 'rubygems'
require 'bundler/setup'

require_relative "imap_facade"
require_relative "../model/feed_item"


module FeedMe
  module Processor
    # Extends the FeedMe::Processor::ImapFacade class and provides means of storing a FeedItem
    # into the given folder
    class ImapSyncer < FeedMe::Processor::ImapFacade
      # Stores the given item in the specified folder; in case the item already exists on the IMAP server
      # in the given folder, then it's not stored/appended
      # @param [FeedMe::Model::FeedItem] feed_item the item to store
      # @param [String] folder_name the folder where to store the item
      def store_item(feed_item, folder_name)
        @logger.info{"Storing item #{feed_item} at #{folder_name}"}
        store_message(folder_name, feed_item.title, feed_item.ts, format_feed_item_body(feed_item), "#{feed_item.msg_id}@feed-me-via-imap.localhost")
      end

      protected
      # Returns a String which is used as the email body
      # @param [FeedMe::Model::FeedItem] feed_item the FeedItem for which a body shall be created
      # @return [String] the body describing the FeedItem
      def format_feed_item_body(feed_item)
        raise ArgumentError, "feed_item must not be nil and of type FeedMe::Model::FeedItem (got: '#{feed_item.class.to_s}'" unless !feed_item.nil? && feed_item.instance_of?(FeedMe::Model::FeedItem)

        ret_val = <<EOS
URL: #{feed_item.uri.to_s}

Title: #{feed_item.title}

#{feed_item.body}
EOS

        return ret_val
      end
    end
  end
end