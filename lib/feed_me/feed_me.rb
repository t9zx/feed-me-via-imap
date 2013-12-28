require 'rubygems'
require 'bundler/setup'

require_relative "utils/logger"

require_relative "config/config"
require_relative "model/feed"
require_relative "processor/feed_reader"
require_relative "processor/imap_syncer"

module FeedMe
  class FeedMeNow
    FEED_ME_VERSION = "1.0.0"

    def initialize
      logger = FeedMe::Utils::Logger.get(self.class.to_s)

      begin
        logger.info{"FeedMe version: #{FEED_ME_VERSION}"}
        logger.info{"Starting to fetch feeds"}

        cfg_file = ARGV[0]
        logger.debug{"Trying to read config file: '#{cfg_file}'"}
        conf = nil
        if cfg_file.nil?
          # no config file was passed
          logger.error{"You need to pass a config file as the first parameter"}
          exit 1
        else
          conf = FeedMe::Config::Config.new(File.new(cfg_file, "r"))
        end
        logger.debug{"Config file read"}

        imap = FeedMe::Processor::ImapSyncer.new(
            conf.value("imap.server"),
            conf.value("imap.user"),
            conf.value("imap.password"),
            conf.value("imap.port"),
            conf.value("imap.ssl")
        )
        imap.login

        # process each feed from the config file
        # TODO - make this more failsafe
        feeds = conf.value("feeds")
        feeds.each do |feed_config|
          feed = FeedMe::Model::Feed.new(URI(feed_config['url']))
          FeedMe::Processor::FeedReader.retrieve_feed(feed)
          feed.feed_items.each do |feed_item|
            imap.store_item(feed_item, feed_config['folder'])
          end
        end

        #feed = FeedMe::Model::Feed.new(URI("http://www.heise.de/newsticker/heise-atom.xml"))
        #FeedMe::Processor::FeedReader.retrieve_feed(feed)
        #feed.feed_items.each do |feed_item|
        #  imap.store_item(feed_item, "Test.Manual")
        #end
      ensure
        imap.logout if imap && imap.logged_in?
      end

      logger.info{"FeedMe stops now"}
    end

  end
end

#logger = FeedMe::Utils::Logger.get("foobar")
#logger.error "Hello"
#FeedMe::FeedMeNow.new