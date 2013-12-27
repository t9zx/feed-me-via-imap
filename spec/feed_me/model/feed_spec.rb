require_relative "../../spec_helper"

require_relative "../../../lib/feed_me/model/feed"
require_relative "../../../lib/feed_me/model/feed_item"

require "uri"

module FeedMe
  module Model
    describe Feed do

      before(:each) do
        @feed = FeedMe::Model::Feed.new(URI("http://localhost"))
      end

      it "can be instantiated" do
        lambda {
          FeedMe::Model::Feed.new(URI("http://localhost"))
        }.should_not raise_error
      end

      it "can't be instantiated when the parameters aren't be the right ones" do
        lambda {
          FeedMe::Model::Feed.new(nil)
          FeedMe::Model::Feed.new("http://localhost")
        }.should raise_error(ArgumentError)
      end


      it "has an URI" do
        @feed.feed_uri.should be_a(URI)
        @feed.feed_uri.to_s.should == "http://localhost"
      end

      it "is immutable" do
        lambda {
          @feed.feed_uri = URI("http://localhost")
        }.should raise_error(NoMethodError)
      end

      context "when a FeedItem for this feed exists" do
        before(:each) do
          @feed_item_stub = double('feed_item')
          @feed_item_stub.stub(:instance_of?).and_return(FeedMe::Model::FeedItem)
        end

        it "can be added to this feed" do
          @feed.add_feed_item(@feed_item_stub)
        end

        it "will not add the same FeedItem instance again" do
          @feed.add_feed_item(@feed_item_stub)
          @feed.add_feed_item(@feed_item_stub)
          expect(@feed.feed_items.size).to eq(1)
        end

        it "will complain if it's not the right argument" do
          expect {
            @feed.add_feed_item(nil)
          }.to raise_error(ArgumentError)

          expect {
            @feed.add_feed_item(1)
          }.to raise_error(ArgumentError)
        end

        it "will allow to retrieve feed_items back from the feed" do
          @feed.add_feed_item(@feed_item_stub)
          expect(@feed.feed_items[0]).to be === @feed_item_stub
        end

        it "will not allow tampering the feed_items array" do
          @feed.add_feed_item(@feed_item_stub)
          expect(@feed.feed_items[0]).to be === @feed_item_stub
          items = @feed.feed_items
          items.clear
          expect(@feed.feed_items[0]).to be === @feed_item_stub
        end
      end

    end
  end
end