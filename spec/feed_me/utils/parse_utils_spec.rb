require_relative "../../spec_helper"

require_relative "../../../lib/feed_me/utils/parse_utils"

module FeedMe
  module Utils
    describe ParseUtils do

      context "when parsing times we find in RSS/ATOM feeds" do

        it "parses ' Mon, 06 Sep 2009 16:20:22 +0000 '" do
          dt = ParseUtils.safe_parse_datetime(" Mon, 06 Sep 2009 16:20:22 +0000 ")
          expect(dt.year).to eq(2009)
          expect(dt.month).to eq(9)
          expect(dt.day).to eq(6)
          expect(dt.hour).to eq(16)
          expect(dt.minute).to eq(20)
          expect(dt.second).to eq(22)
        end

        it "parses ' 2003-12-13T18:30:02Z '" do
          dt = ParseUtils.safe_parse_datetime(" 2003-12-13T18:30:02Z ")
          expect(dt.year).to eq(2003)
          expect(dt.month).to eq(12)
          expect(dt.day).to eq(13)
          expect(dt.hour).to eq(18)
          expect(dt.minute).to eq(30)
          expect(dt.second).to eq(2)
        end

      end

      context "when extracting XML text from XML nodes" do
        pending "retrieves the content" do

        end
      end

    end
  end
end