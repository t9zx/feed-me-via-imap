require 'rubygems'
require 'bundler/setup'

require_relative "utils/logger"

require_relative "model/feed"
require_relative "processor/feed_reader"

module FeedMe
  class FeedMeNow
    def initialize
      logger = FeedMe::Utils::Logger.get(self.to_s)
      logger.info{"Starting to fetch feeds"}

      logger.debug{"Trying to read config file"}
      logger.debug{"Config file read"}

      ##### If you are in doubt, try it out ######
      feed = FeedMe::Model::Feed.new(URI("http://www.heise.de/newsticker/heise-atom.xml"))
      FeedMe::Processor::FeedReader.retrieve_feed(feed)
      ##### I hope all doubts are gone now ######

      logger.info{"FeedMe stops now"}
    end

  end
end

#logger = FeedMe::Utils::Logger.get("foobar")
#logger.error "Hello"
#FeedMe::FeedMeNow.new