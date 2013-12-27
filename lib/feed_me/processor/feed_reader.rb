require 'rubygems'
require 'bundler/setup'

require "date"
require "uri"
require "net/http"
require "net/https"

require "nokogiri"

require_relative "../utils/logger"

require_relative "../model/feed"
require_relative "../model/feed_item"

require_relative "../utils/parse_utils"

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
          case response
            when Net::HTTPSuccess
              logger.debug{"Received HTTPSuccess response"}
              ret_val = response.body
            when Net::HTTPRedirection
              # TODO this can yield to infinite calls; limit this
              logger.debug{"Redirected to #{response['location']}"}
              ret_val = retrieve_feed_content(URI(response['location']))
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
          logger.debug{"Trying to parse XML data"}
          ret_val = Nokogiri.parse(xml_string.to_s)
          logger.debug{"Successfully parsed"}
        rescue Exception => ex
          msg = "Exception while parsing XML: #{ex.message}" << $/
          msg << "for the following XML" << $/
          msg << xml_string
          logger.warn{msg}
          raise FeedMe::ParsingException, msg
        end

        return ret_val
      end

      # Iterates over the items from the feed and creates FeedItem for the feed
      # @param [FeedMe::Model::Feed] feed the feed to read
      # @param [Nokogiri::XML::Document, Nokogiri::HTML::Document] feed_xml the XML document to parse for RSS
      def self.process_rss_feed(feed, feed_xml)
        raise ArgumentError, "Expected a FeedMe::Model::Feed object but got #{feed.class.to_s}" unless feed.kind_of?(FeedMe::Model::Feed)
        raise ArgumentError, "Expected Nokogiri::XML::Document or Nokogiri::HTML::Document but got #{feed_xml.class.to_s}" unless feed_xml.instance_of?(Nokogiri::XML::Document) || feed_xml.instance_of?(Nokogiri::HTML::Document)

        # iterate over each entry, extract the interesting information
        feed_xml.xpath('/rss/channel/item').each do |item|
          title = FeedMe::Utils::ParseUtils.safe_xpath_text(item, './title', 'Unknown Title')
          body = FeedMe::Utils::ParseUtils.safe_xpath_text(item, './description', 'No description given.')
          uri = URI(FeedMe::Utils::ParseUtils.safe_xpath_text(item, './link', ''))
          msg_id = FeedMe::Utils::ParseUtils.safe_xpath_text(item, './guid', '')
          ts = FeedMe::Utils::ParseUtils.safe_parse_datetime(FeedMe::Utils::ParseUtils.safe_xpath_text(item, './pubDate', DateTime.now))

          create_feed_item(feed, title, body, uri, msg_id, ts)
        end
      end

      # Iterates over the items from the feed and creates FeedItem for the feed
      # @param [FeedMe::Model::Feed] feed the feed to read
      # @param [Nokogiri::XML::Document, Nokogiri::HTML::Document] feed_xml the XML document to parse for ATOM
      def self.process_atom_feed(feed, feed_xml)
        raise ArgumentError, "Expected a FeedMe::Model::Feed object but got #{feed.class.to_s}" unless feed.kind_of?(FeedMe::Model::Feed)
        raise ArgumentError, "Expected Nokogiri::XML::Document or Nokogiri::HTML::Document but got #{feed_xml.class.to_s}" unless feed_xml.instance_of?(Nokogiri::XML::Document) || feed_xml.instance_of?(Nokogiri::HTML::Document)

        # iterate over each entry, extract the interesting information
        feed_xml.xpath('/feed/entry').each do |item|
          title = FeedMe::Utils::ParseUtils.safe_xpath_text(item, './title', 'Unknown Title')
          body = FeedMe::Utils::ParseUtils.safe_xpath_text(item, './summary', 'No description given.')
          uri = URI(FeedMe::Utils::ParseUtils.safe_xpath_text(item, './link', ''))
          msg_id =FeedMe::Utils::ParseUtils. safe_xpath_text(item, './id', '')
          ts = FeedMe::Utils::ParseUtils.safe_parse_datetime(FeedMe::Utils::ParseUtils.safe_xpath_text(item, './updated', DateTime.now))

          create_feed_item(feed, title, body, uri, msg_id, ts)
        end
      end

      private
      # Creates a FeedItem with the given information; in case the msg_id is an empty string or nil, then a UUID will be
      # generated
      # @param [FeedMe::Model::Feed] feed the feed used
      # @param [String] title
      # @param [String] body
      # @param [URI] uri
      # @param [String] msg_id
      # @param [Time] ts
      # @returns [FeedMe::Model::FeedItem] the FeedItem created
      def self.create_feed_item(feed, title, body, uri, msg_id, ts)
        logger = FeedMe::Utils::Logger.get(self)

        if msg_id.empty?
          # TODO - check if makes sense to created the msg_id based on the title to avoid creating the same records over and over again on the IMAP
          logger.warn{"Unable to retrieve a guid for #{item.to_s} - generating one on my own"}
          msg_id = UUIDTools::UUID.timestamp_create.to_s
        end

        ret_val = FeedMe::Model::FeedItem.new(feed, title, body, uri, msg_id, ts)

        return ret_val
      end


    end
  end
end