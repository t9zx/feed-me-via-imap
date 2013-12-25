require_relative "../../spec_helper"

require_relative "../../../lib/feed_me/config/config"
require_relative "../../../lib/feed_me/processor/imap_syncer"

module FeedMe
  module Processor
    describe ImapSyncer do

      # For the time being, you need to create a file at conf/config_unit_test.yaml pointing to a LDAP server we can target by the unit-test
      let(:config) {FeedMe::Config::Config.new(File.new("#{File.dirname(__FILE__)}/../../../conf/config_unit_test.yaml", "r"))}
      let(:imap_server) {config.value("imap.server")}
      let(:imap_user) {config.value("imap.user")}
      let(:imap_pass) {config.value("imap.password")}
      let(:imap_port) {Integer(config.value("imap.port"))}
      let(:imap_ssl) {config.value("imap.ssl")}

      it "can be initialized" do
        expect {
          FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, imap_pass, imap_port, imap_ssl)
        }.to_not raise_error
      end

      context "when handling a FeedItem" do
        before do
          @feed = FeedMe::Model::Feed.new(URI("http://localhost"))
          @feed_item = FeedMe::Model::FeedItem.new(@feed, "title", "body", URI("http://localhost/foo"), "12345")
          @folder = "RSpec/ImapSyncerSpec"
        end

        before(:each) do
          @imap = FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, imap_pass, imap_port, imap_ssl)
          @imap.login
        end

        it "stores new items" do
          expect {
            @imap.store_item(@feed_item, @folder)
          }.to_not raise_error
        end

        pending "skips already existing items" do

        end

        context "#format_feed_item_body" do
          it "accepts only FeedItem entries" do
            expect {
              @imap.send(:format_feed_item_body, nil)
            }.to raise_error(ArgumentError)

            expect {
              @imap.send(:format_feed_item_body, 1)
            }.to raise_error(ArgumentError)
          end

          it "returns a formatted body" do
            body = @imap.send(:format_feed_item_body, @feed_item)
            expect(body).to match(/#{@feed_item.uri.to_s}/)
            expect(body).to match(/#{@feed_item.title}/)
            expect(body).to match(/#{@feed_item.body}/)
          end
        end
      end

    end
  end
end