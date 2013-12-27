require_relative "../../../lib/feed_me/utils/logger"

module FeedMe
  module Utils
    describe Logger do

      it "returns a logger" do
        lambda {
          l = FeedMe::Utils::Logger.get("foo")
          l.should_not be_nil

          l = FeedMe::Utils::Logger.get(String)
          l.should_not be_nil
        }.should_not raise_error
      end

      it "complains when wrong parameter type is passed" do
        lambda {
          l = FeedMe::Utils::Logger.get(1)
          l.should_not be_nil
        }.should raise_error(ArgumentError)
      end

    end
  end
end