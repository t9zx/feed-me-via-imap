require_relative "../../spec_helper"

require 'uuidtools'

require_relative "../../../lib/feed_me/processor/imap_syncer"
require_relative "../../../lib/feed_me/config/config"

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

      context "when incorrect parameters are passed to the constructor it will complain" do
        it "will fail when we pass incorrect imap_server" do
          expect {
            FeedMe::Processor::ImapSyncer.new(nil, imap_user, imap_pass, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)

          expect {
            FeedMe::Processor::ImapSyncer.new(1, imap_user, imap_pass, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)
        end

        it "will fail when we pass incorrect imap_user" do
          expect {
            FeedMe::Processor::ImapSyncer.new(imap_server, nil, imap_pass, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)

          expect {
            FeedMe::Processor::ImapSyncer.new(imap_server, 1, imap_pass, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)
        end

        it "will fail when we pass incorrect imap_password" do
          expect {
            FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, nil, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)

          expect {
            FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, 1, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)
        end

        it "will fail when we pass incorrect imap_port" do
          expect {
            FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, imap_pass, nil, imap_ssl)
          }.to raise_error(ArgumentError)

          expect {
            FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, imap_pass, "1", imap_ssl)
          }.to raise_error(ArgumentError)
        end

        it "will fail when we pass incorrect imap_ssl" do
          expect {
            FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, imap_pass, imap_port, nil)
          }.to raise_error(ArgumentError)

          expect {
            FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, imap_pass, imap_port, 1)
          }.to raise_error(ArgumentError)
        end

      end

      it "will complain in case we want to open an SSL connection" do
        expect {
          FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, imap_pass, imap_port, true)
        }.to raise_error(FeedMe::FeedMeError)
      end

      pending "supports SSL connections as well" do
      end

      context "when handling logins" do
        before(:each) do
          @imap = FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, imap_pass, imap_port, imap_ssl)
        end

        it "will allow me to login to the IMAP server" do
          expect {
            @imap.login
          }.to_not raise_error
        end

        it "will complain in case I'm trying to login two times" do
          expect {
            @imap.login
          }.to_not raise_error

          expect {
            @imap.login
          }.to raise_error(FeedMe::ImapException)
        end
      end

      context "when handling logouts" do

        before(:each) do
          @imap = FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, imap_pass, imap_port, imap_ssl)
        end

        it "allows me to logout in case I'm logged in and won't allow me to call it a 2nd time" do
          expect {
            @imap.login
            @imap.logout
          }.to_not raise_error

          expect {
            @imap.logout
          }.to raise_error(FeedMe::ImapException)
        end

        it "will complain in case I'm not logged in" do
          expect {
            @imap.logout
          }.to raise_error(FeedMe::ImapException)
        end
      end

      context "allows storing of messagges" do
        let(:folder_name) {"RSpec/ImapSyncerSpec"}
        let(:subject) {"Subject #{Time.now.utc.to_s}"}
        let(:time) {Time.now.utc}
        let(:body) {"Body of the email #{Time.now.utc.to_s}"}
        before(:each) do
          @imap = FeedMe::Processor::ImapSyncer.new(imap_server, imap_user, imap_pass, imap_port, imap_ssl)
        end

        context "will complain in case the passed parameters are not correct" do
          it "folder_name must be proper" do
            @imap.login
            expect {
              @imap.send(:store_message, nil, subject, time, body)
            }.to raise_error(ArgumentError)

            expect {
              @imap.send(:store_message, 1, subject, time, body)
            }.to raise_error(ArgumentError)
          end

          it "subject must be proper" do
            @imap.login
            expect {
              @imap.send(:store_message, folder_name, nil, time, body)
            }.to raise_error(ArgumentError)

            expect {
              @imap.send(:store_message, folder_name, 1, time, body)
            }.to raise_error(ArgumentError)

          end

          it "time must be proper" do
            @imap.login
            expect {
              @imap.send(:store_message, folder_name, subject, nil, body)
            }.to raise_error(ArgumentError)

            expect {
              @imap.send(:store_message, folder_name, subject, 1, body)
            }.to raise_error(ArgumentError)
          end

          it "body must be proper" do
            @imap.login
            expect {
              @imap.send(:store_message, folder_name, subject, time, nil)
            }.to raise_error(ArgumentError)

            expect {
              @imap.send(:store_message, folder_name, subject, time, 1)
            }.to raise_error(ArgumentError)
          end

        end

        it "it will complain in case we are not yet logged in" do
          expect {
            @imap.send(:store_message, folder_name, subject, time, body)
          }.to raise_error(FeedMe::ImapException)
        end

        it "will store a sample message" do
          expect {
            @imap.login
            @imap.send(:store_message, folder_name, subject, time, body)
          }.to_not raise_error
        end

        it "will create a folder in case it doesn't exist yet" do
          expect {
            unique_folder_name = "#{folder_name}/#{UUIDTools::UUID.timestamp_create.to_s}"
            @imap.login
            @imap.send(:store_message, unique_folder_name, subject, time, body)
          }.to_not raise_error
        end

        context "#create_message" do
          it "returns a valid formatted message" do
            msg_manual = <<EOS
Subject: #{subject}
From: sender@localhost
To: recipient@localhost

#{body}
EOS

            msg = @imap.send(:create_message, subject, "sender@localhost", "recipient@localhost", time, body)
            expect(msg).to eq(msg_manual.gsub(/\r\n?|\n/, "\r\n"))
          end
        end

      end
    end
  end
end