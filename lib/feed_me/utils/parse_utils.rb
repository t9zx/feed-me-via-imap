module FeedMe
  module Utils
    # Combines various convenience methods for related to text extractions/parsing.
    class ParseUtils

      # Returns the text content of the node specified by xpath from xml
      # @param [Nokogiri::XML::Element, Nokogiri::XML::Document, Nokogiri::HTML::Document] the XML document
      # @param [String] xpath the XPath to retrieve
      # @param [String] default_value returned in case the Xpath is not found
      # @return [String] the text found or the default value in case the node was not found
      def self.safe_xpath_text(xml, xpath, default_value)
        logger = FeedMe::Utils::Logger.get(self)

        ret_val = nil
        begin
          ret_val = (val = xml.xpath(xpath)[0]).nil? ? default_value : val.text
        rescue Exception => ex
          logger.error{"Exception caught while getting element: #{ex.message}#{$/}#{ex.backtrace.join($/)}"}
          ret_val = default_value
        end

        return ret_val
      end

      # Tries to parse an arbitrary string as a Date/Time
      # @param [String] date_time_string
      # @return [DateTime]
      def self.safe_parse_datetime(date_time_string)
        return DateTime.parse(date_time_string)
      end

    end
  end
end