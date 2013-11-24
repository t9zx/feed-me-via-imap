require_relative "../../../lib/feed_me/model/feed"

require "uri"

module FeedMe
  module Model
    describe Feed do

      before(:each) do
        @feed = FeedMe::Model::Feed.new(Feed::RSS, URI("http://localhost"))
      end

      it "can be instantiated" do
        lambda {
          FeedMe::Model::Feed.new(Feed::RSS, URI("http://localhost"))
        }.should_not raise_error
      end

      it "can't be instantiated when the parameters aren't be the right ones" do
        lambda {
          FeedMe::Model::Feed.new(nil, URI("http://localhost"))
          FeedMe::Model::Feed.new(:foo, URI("http://localhost"))
        }.should raise_error(ArgumentError)

        lambda {
          FeedMe::Model::Feed.new(Feed::RSS, nil)
          FeedMe::Model::Feed.new(Feed::RSS, "http://localhost")
        }.should raise_error(ArgumentError)
      end


      it "has a feed_type" do
        @feed.feed_type.should == Feed::RSS
      end

      it "has an URI" do
        @feed.feed_uri.should be_a(URI)
        @feed.feed_uri.to_s.should == "http://localhost"
      end

      it "is immutable" do
        lambda {
          @feed.feed_type = Feed::RSS
        }.should raise_error(NoMethodError)

        lambda {
          @feed.feed_uri = URI("http://localhost")
        }.should raise_error(NoMethodError)
      end

    end
  end
end