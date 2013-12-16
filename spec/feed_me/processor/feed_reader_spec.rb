require_relative "../../spec_helper"

require_relative "../../../lib/feed_me/model/feed"
require_relative "../../../lib/feed_me/processor/feed_reader"

require "uri"
require "nokogiri"

module FeedMe
  module Processor
    describe FeedReader do

      let(:feed_uri) {URI("http://localhost:1234/foobar")}
      let(:feed_uri_redirected) {URI("http://localhost:1234/foobar_redirected")}
      let(:feed_content_rss) {IO.read("#{File.dirname(__FILE__)}/../../fixtures/sample-rss.xml")}
      let(:feed_content_atom) {IO.read("#{File.dirname(__FILE__)}/../../fixtures/sample-atom.xml")}
      let(:feed_rss) {FeedMe::Model::Feed.new(FeedMe::Model::Feed::RSS, feed_uri)}
      let(:feed_atom) {FeedMe::Model::Feed.new(FeedMe::Model::Feed::ATOM, feed_uri)}

      it "is possible to retrieve a RSS feed" do
        stub_request(:get, feed_uri.to_s).to_return(:body => feed_content_rss, :status => 200)

        expect {
          FeedMe::Processor::FeedReader.retrieve_feed(feed_rss)
        }.not_to raise_error
      end

      it "is possible to retrieve a RSS feed with a redirect" do
        stub_request(:get, feed_uri.to_s).to_return(:body => "", :status => 302, :headers => { 'Location' => feed_uri_redirected.to_s})
        stub_request(:get, feed_uri_redirected.to_s).to_return(:body => feed_content_rss, :status => 200)

        expect {
          FeedMe::Processor::FeedReader.retrieve_feed(feed_rss)
        }.not_to raise_error
      end

      it "is possible to retrieve an ATOM feed" do
        stub_request(:get, feed_uri.to_s).to_return(:body => feed_content_atom, :status => 200)

        expect {
          FeedMe::Processor::FeedReader.retrieve_feed(feed_atom)
        }.not_to raise_error
      end

      it "will complain when we pass not the right object when retrieving a feed" do
        expect {
          FeedMe::Processor::FeedReader.retrieve_feed("http://foo")
        }.to raise_error(ArgumentError)
      end

      it "is possible to pass a URI to retrieve_feed_content" do
        stub_request(:get, feed_uri.to_s).to_return(:body => feed_content_rss, :status => 200)
        fc = nil
        expect {
          fc = FeedMe::Processor::FeedReader.retrieve_feed_content(feed_uri)
        }.not_to raise_error

        expect(fc).to eq(feed_content_rss)
      end

      it "is possible to pass a URI to retrieve_feed_content but as we return non 200 we will get an empty string returned" do
        stub_request(:get, feed_uri.to_s).to_return(:body => feed_content_rss, :status => 404)
        fc = nil
        expect {
          fc = FeedMe::Processor::FeedReader.retrieve_feed_content(feed_uri)
        }.not_to raise_error

        expect(fc).to eq("")
      end

      it "is only possible to pass a URI to retrieve_feed_content" do
        expect {
          FeedMe::Processor::FeedReader.retrieve_feed_content("http://foo")
        }.to raise_error(ArgumentError)

      end

      it "is able to parse XML strings" do
        xml = nil
        expect {
          xml = FeedMe::Processor::FeedReader.parse_content(feed_content_rss)
        }.not_to raise_error

        expect(xml).to be_a(Nokogiri::XML::Document)
        expect(xml.xpath('//item/title')).to have(2).elements
      end

    end
  end
end

