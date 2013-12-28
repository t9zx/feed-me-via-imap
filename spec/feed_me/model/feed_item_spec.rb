require_relative "../../../lib/feed_me/model/feed"
require_relative "../../../lib/feed_me/model/feed_item"

require "date"
require "uri"

module FeedMe
  module Model
    describe FeedItem do

      before(:each) do
        @feed = FeedMe::Model::Feed.new(URI("http://localhost"))
        @feed_item = FeedMe::Model::FeedItem.new(@feed, "title", "body", URI("http://localhost/foo"), "12345", DateTime.now)
      end

      it "can be instantiated" do
        fi = nil
        lambda {
          fi = FeedMe::Model::FeedItem.new(@feed, "title", "body", URI("http://localhost/foo"), "12345", DateTime.now)
        }.should_not raise_error
        expect(@feed.feed_items).to include(fi)
      end

      it "should complain when the passed paramters aren't proper ones" do
        lambda {
          FeedMe::Model::FeedItem.new("foo", "title", "body", URI("http://localhost/foo"), "12345", DateTime.now)
        }.should raise_error(ArgumentError)
        lambda {
          FeedMe::Model::FeedItem.new(@feed, 1, "body", URI("http://localhost/foo"), "12345", DateTime.now)
        }.should raise_error(ArgumentError)
        lambda {
          FeedMe::Model::FeedItem.new(@feed, "title", 1, URI("http://localhost/foo"), "12345", DateTime.now)
        }.should raise_error(ArgumentError)
        lambda {
          FeedMe::Model::FeedItem.new(@feed, "title", "body", "http://localhost/foo", "12345", DateTime.now)
        }.should raise_error(ArgumentError)
        lambda {
          FeedMe::Model::FeedItem.new(@feed, "title", "body", URI("http://localhost/foo"), 1, DateTime.now)
        }.should raise_error(ArgumentError)
        lambda {
          FeedMe::Model::FeedItem.new(@feed, "title", "body", URI("http://localhost/foo"), "12345", 1)
        }.should raise_error(ArgumentError)
      end

    end
  end
end