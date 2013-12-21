require_relative "../../../lib/feed_me/model/feed"
require_relative "../../../lib/feed_me/model/feed_item"

require "uri"

module FeedMe
  module Model
    describe FeedItem do

      before(:each) do
        @feed = FeedMe::Model::Feed.new(URI("http://localhost"))
        @feed_item = FeedMe::Model::FeedItem.new(@feed, "title", "body", URI("http://localhost/foo"), "12345")
      end

      it "can be instantiated" do
        lambda {
          FeedMe::Model::FeedItem.new(@feed, "title", "body", URI("http://localhost/foo"), "12345")
        }.should_not raise_error
      end

      it "should complain when the passed paramters aren't proper ones" do
        lambda {
          FeedMe::Model::FeedItem.new("foo", "title", "body", URI("http://localhost/foo"), "12345")
        }.should raise_error(ArgumentError)
        lambda {
          FeedMe::Model::FeedItem.new(@feed, 1, "body", URI("http://localhost/foo"), "12345")
        }.should raise_error(ArgumentError)
        lambda {
          FeedMe::Model::FeedItem.new(@feed, "title", 1, URI("http://localhost/foo"), "12345")
        }.should raise_error(ArgumentError)
        lambda {
          FeedMe::Model::FeedItem.new(@feed, "title", "body", "http://localhost/foo", "12345")
        }.should raise_error(ArgumentError)
        lambda {
          FeedMe::Model::FeedItem.new(@feed, "title", "body", URI("http://localhost/foo"), 1)
        }.should raise_error(ArgumentError)
      end

    end
  end
end