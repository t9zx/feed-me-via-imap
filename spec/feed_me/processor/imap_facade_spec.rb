require_relative "../../spec_helper"

require 'uuidtools'

require_relative "../../../lib/feed_me/processor/imap_facade"
require_relative "../../../lib/feed_me/config/config"

module FeedMe
  module Processor
    describe ImapFacade do

      # For the time being, you need to create a file at conf/config_unit_test.yaml pointing to a LDAP server we can target by the unit-test
      let(:config) {FeedMe::Config::Config.new(File.new("#{File.dirname(__FILE__)}/../../../conf/config_unit_test.yaml", "r"))}
      let(:imap_server) {config.value("imap.server")}
      let(:imap_user) {config.value("imap.user")}
      let(:imap_pass) {config.value("imap.password")}
      let(:imap_port) {Integer(config.value("imap.port"))}
      let(:imap_ssl) {config.value("imap.ssl")}

      it "can be initialized" do
        expect {
          FeedMe::Processor::ImapFacade.new(imap_server, imap_user, imap_pass, imap_port, imap_ssl)
        }.to_not raise_error
      end

      context "when incorrect parameters are passed to the constructor it will complain" do
        it "will fail when we pass incorrect imap_server" do
          expect {
            FeedMe::Processor::ImapFacade.new(nil, imap_user, imap_pass, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)

          expect {
            FeedMe::Processor::ImapFacade.new(1, imap_user, imap_pass, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)
        end

        it "will fail when we pass incorrect imap_user" do
          expect {
            FeedMe::Processor::ImapFacade.new(imap_server, nil, imap_pass, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)

          expect {
            FeedMe::Processor::ImapFacade.new(imap_server, 1, imap_pass, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)
        end

        it "will fail when we pass incorrect imap_password" do
          expect {
            FeedMe::Processor::ImapFacade.new(imap_server, imap_user, nil, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)

          expect {
            FeedMe::Processor::ImapFacade.new(imap_server, imap_user, 1, imap_port, imap_ssl)
          }.to raise_error(ArgumentError)
        end

        it "will fail when we pass incorrect imap_port" do
          expect {
            FeedMe::Processor::ImapFacade.new(imap_server, imap_user, imap_pass, nil, imap_ssl)
          }.to raise_error(ArgumentError)

          expect {
            FeedMe::Processor::ImapFacade.new(imap_server, imap_user, imap_pass, "1", imap_ssl)
          }.to raise_error(ArgumentError)
        end

        it "will fail when we pass incorrect imap_ssl" do
          expect {
            FeedMe::Processor::ImapFacade.new(imap_server, imap_user, imap_pass, imap_port, nil)
          }.to raise_error(ArgumentError)

          expect {
            FeedMe::Processor::ImapFacade.new(imap_server, imap_user, imap_pass, imap_port, 1)
          }.to raise_error(ArgumentError)
        end

      end

      #it "will complain in case we want to open an SSL connection" do
      #  expect {
      #    FeedMe::Processor::ImapFacade.new(imap_server, imap_user, imap_pass, imap_port, true)
      #  }.to raise_error(FeedMe::FeedMeError)
      #end

      it "supports SSL connections as well" do
        expect {
          imap_facade = FeedMe::Processor::ImapFacade.new(imap_server, imap_user, imap_pass, 993, true)
          imap_facade.login
          imap_facade.logout
        }.to_not raise_error()
      end

      context "when handling logins" do
        before(:each) do
          @imap = FeedMe::Processor::ImapFacade.new(imap_server, imap_user, imap_pass, imap_port, imap_ssl)
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
          @imap = FeedMe::Processor::ImapFacade.new(imap_server, imap_user, imap_pass, imap_port, imap_ssl)
        end

        it "allows me to logout in case I'm logged in and won't allow me to call it a 2nd time" do
          expect(@imap.logged_in?).to be_false
          expect {
            @imap.login
            expect(@imap.logged_in?).to be_true
            @imap.logout
          }.to_not raise_error
          expect(@imap.logged_in?).to be_false

          expect {
            @imap.logout
          }.to raise_error(FeedMe::ImapException)
          expect(@imap.logged_in?).to be_false
        end

        it "will complain in case I'm not logged in" do
          expect(@imap.logged_in?).to be_false
          expect {
            @imap.logout
          }.to raise_error(FeedMe::ImapException)
          expect(@imap.logged_in?).to be_false
        end
      end

      context "allows storing of messagges" do
        let(:folder_name) {"RSpec/ImapFacadeSpec"}
        let(:subject) {"Subject #{Time.now.utc.to_s}"}
        let(:time) {DateTime.parse("2003-12-13T18:30:02Z")}
        let(:body) {"Body of the email #{Time.now.utc.to_s}"}
        let(:msg_id) {"#{UUIDTools::UUID.timestamp_create}@feed-me-via-imap.localhost"}
        before(:each) do
          @imap = FeedMe::Processor::ImapFacade.new(imap_server, imap_user, imap_pass, imap_port, imap_ssl)
        end

        context "will complain in case the passed parameters are not correct" do
          it "folder_name must be proper" do
            @imap.login
            expect {
              @imap.send(:store_message, nil, subject, time, body, msg_id)
            }.to raise_error(ArgumentError)

            expect {
              @imap.send(:store_message, 1, subject, time, body, msg_id)
            }.to raise_error(ArgumentError)
          end

          it "subject must be proper" do
            @imap.login
            expect {
              @imap.send(:store_message, folder_name, nil, time, body, msg_id)
            }.to raise_error(ArgumentError)

            expect {
              @imap.send(:store_message, folder_name, 1, time, body, msg_id)
            }.to raise_error(ArgumentError)

          end

          it "time must be proper" do
            @imap.login
            expect {
              @imap.send(:store_message, folder_name, subject, nil, body, msg_id)
            }.to raise_error(ArgumentError)

            expect {
              @imap.send(:store_message, folder_name, subject, 1, body, msg_id)
            }.to raise_error(ArgumentError)
          end

          it "body must be proper" do
            @imap.login
            expect {
              @imap.send(:store_message, folder_name, subject, time, nil, msg_id)
            }.to raise_error(ArgumentError)

            expect {
              @imap.send(:store_message, folder_name, subject, time, 1, msg_id)
            }.to raise_error(ArgumentError)
          end

          it "msg_id must be proper" do
            @imap.login
            expect {
              @imap.send(:store_message, folder_name, subject, time, body, nil)
            }.to raise_error(ArgumentError)

            expect {
              @imap.send(:store_message, folder_name, subject, time, body, 1)
            }.to raise_error(ArgumentError)
          end

        end

        it "it will complain in case we are not yet logged in" do
          expect(@imap.logged_in?).to be_false
          expect {
            @imap.send(:store_message, folder_name, subject, time, body, msg_id)
          }.to raise_error(FeedMe::ImapException)
          expect(@imap.logged_in?).to be_false
        end

        it "will store a sample message" do
          expect {
            @imap.login
            @imap.send(:store_message, folder_name, subject, time, body, msg_id)
          }.to_not raise_error
        end

        it "will create a folder in case it doesn't exist yet" do
          expect {
            unique_folder_name = "#{folder_name}/#{UUIDTools::UUID.timestamp_create.to_s}"
            @imap.login
            @imap.send(:store_message, unique_folder_name, subject, time, body, msg_id)
          }.to_not raise_error
        end

        context "#message_exists?" do
          let(:folder_name) {"RSpec/ImapFacadeSpec"}
          let(:folder_name_unknown) {"RSpec/ImapFacadeSpec/#{UUIDTools::UUID.timestamp_create}"}
          let(:subject) {"Subject #{Time.now.utc.to_s}"}
          let(:time) {DateTime.parse("2003-12-13T18:30:02Z")}
          let(:body) {"Body of the email #{Time.now.utc.to_s}"}
          let(:msg_id) {"#{UUIDTools::UUID.timestamp_create}@feed-me-via-imap.localhost"}
          let(:msg_id_unknown) {"#{UUIDTools::UUID.timestamp_create}@feed-me-via-imap.localhost"}
          before(:each) do
            @imap = FeedMe::Processor::ImapFacade.new(imap_server, imap_user, imap_pass, imap_port, imap_ssl)
          end

          it "will return false in case a message is not found" do
            @imap.login
            @imap.send(:store_message, folder_name, subject, time, body, msg_id)
            expect(@imap.send(:message_exists?, folder_name, msg_id_unknown)).to be_false
          end

          it "will return true in case a message is found" do
            @imap.login
            @imap.send(:store_message, folder_name, subject, time, body, msg_id)
            expect(@imap.send(:message_exists?, folder_name, msg_id)).to be_true
          end

          context "when incorrect parameters are passed" do
            it "will complain for incorrect folder_name" do
              expect {
                @imap.login
                @imap.send(:message_exists?, nil, msg_id)
              }.to raise_error(ArgumentError)

              expect {
                @imap.send(:message_exists?, 1, msg_id)
              }.to raise_error(ArgumentError)
            end

            it "will complain for incorrect msg_id" do
              expect {
                @imap.login
                @imap.send(:message_exists?, folder_name, nil)
              }.to raise_error(ArgumentError)

              expect {
                @imap.send(:message_exists?, folder_name, 1)
              }.to raise_error(ArgumentError)
            end
          end

          it "will handle a folder name which doesn't exist on the IMAP" do
            @imap.login
            @imap.send(:store_message, folder_name, subject, time, body, msg_id)
            expect(@imap.send(:message_exists?, folder_name_unknown, msg_id)).to be_false
          end


          it "will complain in case we are not yet logged in" do
            expect(@imap.logged_in?).to be_false
            expect {
              @imap.send(:message_exists?, folder_name, msg_id)
            }.to raise_error(FeedMe::ImapException)
            expect(@imap.logged_in?).to be_false
          end
        end

        context "#create_message" do
          it "returns a valid formatted message" do
            msg_manual = <<EOS
Subject: #{subject}
From: sender@localhost
To: recipient@localhost
#{FeedMe::Processor::ImapFacade::FEED_ME_IMAP_HEADER}: foobar@localhost
Date: #{time.rfc2822}

#{body}
EOS

            msg = @imap.send(:create_message, subject, "sender@localhost", "recipient@localhost", time, body, "foobar@localhost")
            expect(msg).to eq(msg_manual.gsub(/\r\n?|\n/, "\r\n"))
          end
        end

      end
    end
  end
end