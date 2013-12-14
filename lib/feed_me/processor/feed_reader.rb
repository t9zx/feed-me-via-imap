require 'rubygems'
require 'bundler/setup'

require "uri"
require "net/http"
require "net/https"

require "nokogiri"

require_relative "../utils/logger"

require_relative "../model/feed"
require_relative "../model/feed_item"

require_relative "../exceptions/parsing_exception"

module FeedMe
  module Processor
    # This class retrieves the items from a feed via the internet
    class FeedReader
      # Connects to the feeds URL, reads the feed, parses it and creates FeedItem entries
      # In case we have issues connecting to the feed, issues parsing the feed, ... we will log the issue and won't
      # collect FeedItems; the caller will only notice that there are no FeedItems returned; thus he won't know if
      # something went wrong or the feed simply has no items at all
      # @param [FeedMe::Model::Feed] feed the feed to read
      def self.retrieve_feed(feed)
        raise ArgumentError, "Expected a FeedMe::Model::Feed object but got #{feed.class.to_s}" unless feed.kind_of?(FeedMe::Model::Feed)
        logger = FeedMe::Utils::Logger.get(self)

        feed_content = retrieve_feed_content(feed.feed_uri)
        feed_xml = parse_content(feed_content)

        #puts feed_content.to_s
        #puts feed_xml.to_s

        # do we have a ATOM, RSS or some unknown content
        case
          when feed_xml.xpath('/rss/channel/item/title')
            logger.debug{"#{feed} seems to be a RSS feed"}
            process_rss_feed(feed, feed_xml)
          when feed_xml.xpath('/feed/entry/title')
            logger.debug{ "#{feed} seems to be an ATOM feed"}
            process_atom_feed(feed, feed_xml)
          else
            logger.warn{"Unable to retrieve any sensible items from #{feed}"}
        end

      end

      protected
      # Opens a connection to the given URL and returns the content read as a String
      # In case we hit any kind of error connecting there or or getting a non 200 response, we will return an empty String
      # @param [URI] the URI to read
      # @returns [String] the content retrieved from the URI
      def self.retrieve_feed_content(feed_uri)
        raise ArgumentError, "Expected a URI but got #{feed_uri.class.to_s}" unless feed_uri.kind_of?(URI)
        logger = FeedMe::Utils::Logger.get(self)

        ret_val = ""
        begin
          logger.debug{"Requesting #{feed_uri.to_s}"}
          response = Net::HTTP.get_response(feed_uri)
          if response.instance_of?(Net::HTTPOK)
            logger.debug{"Received HTTPOK response"}
            ret_val = response.body
          else
            logger.warn{"Received response: #{response.class} (#{response.code})"}
          end
        rescue Exception => ex
          msg = "While trying to read #{feed_uri.to_s} the following exception was encountered: #{ex.message}"
          msg << $/
          msg << ex.backtrace.join($/)
          logger.warn{msg}
          ret_val = ""
        end

        return ret_val
      end

      # Parses a string and returns it as a (Nokogiri) Document. In case the parsing fails, an exception will be raised.
      # @param [#to_s] xml_string must be something which has ha .to_s method (which should return a XML)
      # @return [Nokogiri::XML::Document, Nokogiri::HTML::Document]
      # @throws [FeedMe::ParsingException]
      def self.parse_content(xml_string)
        logger = FeedMe::Utils::Logger.get(self)

        ret_val = nil
        begin
          logger.debug{"Trying to parse XML string: #{xml_string.to_s}"}
          ret_val = Nokogiri.parse(xml_string.to_s)
          logger.debug{"Successfully parsed"}
        rescue Exception => ex
          logger.warn{"Exception while parsing XML: #{ex.message}"}
          raise FeedMe::ParsingException, ex.message
        end

        return ret_val
      end

      # Iterates over the items from the feed and creates FeedItem for the feed
      # @param [FeedMe::Model::Feed] feed the feed to read
      # @param [Nokogiri::XML::Document, Nokogiri::HTML::Document] feed_xml
      def self.process_rss_feed(feed, feed_xml)
        raise ArgumentError, "Expected a FeedMe::Model::Feed object but got #{feed.class.to_s}" unless feed.kind_of?(FeedMe::Model::Feed)
        raise ArgumentError, "Expected Nokogiri::XML::Document or Nokogiri::HTML::Document but got #{feed_xml.class.to_s}" unless feed_xml.instance_of?(Nokogiri::XML::Document) || feed_xml.instance_of?(Nokogiri::HTML::Document)

        logger = FeedMe::Utils::Logger.get(self)

        # iterate over each entry, extract the interesting information
        feed_xml.xpath('/rss/channel/item').each do |item|
          # TODO - this must be more failsafe here
          title = item.xpath('./title')[0].text
          body = item.xpath('./description')[0].text
          uri = URI(item.xpath('./link')[0].text)
          msg_id = item.xpath('./guid')[0].text

          fi = FeedMe::Model::FeedItem.new(feed, title, body, uri, msg_id)
          logger.debug{"Retrieved/parsed: #{fi}"}
        end
      end

      # Iterates over the items from the feed and creates FeedItem for the feed
      # @param [FeedMe::Model::Feed] feed the feed to read
      # @param [Nokogiri::XML::Document, Nokogiri::HTML::Document] feed_xml
      def self.process_atom_feed(feed, feed_xml)
        raise ArgumentError, "Expected a FeedMe::Model::Feed object but got #{feed.class.to_s}" unless feed.kind_of?(FeedMe::Model::Feed)
        raise ArgumentError, "Expected Nokogiri::XML::Document or Nokogiri::HTML::Document but got #{feed_xml.class.to_s}" unless feed_xml.instance_of?(Nokogiri::XML::Document) || feed_xml.instance_of?(Nokogiri::HTML::Document)

        logger = FeedMe::Utils::Logger.get(self)

        # iterate over each entry, extract the interesting information
        feed_xml.xpath('/feed/entry').each do |item|
          # TODO - this must be more failsafe here
          title = item.xpath('./title')[0].text
          body = item.xpath('./summary')[0].text
          uri = URI(item.xpath('./link')[0].text)
          msg_id = item.xpath('./id')[0].text

          fi = FeedMe::Model::FeedItem.new(feed, title, body, uri, msg_id)
          logger.debug{"Retrieved/parsed: #{fi}"}
        end
      end
    end
  end
end