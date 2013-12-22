require 'rubygems'
require 'bundler/setup'

require 'net/imap'

require_relative '../exceptions/imap_exception'
require_relative '../exceptions/feed_me_error'

module FeedMe
  module Processor
    class ImapSyncer
      # Synchronizes a given Feed (with it's FeedItems) with an IMAP Server
      # Synchronization is one way only; if there is a FeedItem which is not yet on the IMAP server, then we will store
      # it there
      # You need to call the login method before doing any further actions; once you are done, you should call logout
      # @param [String] imap_server the server to connect to
      # @param [String] imap_user the IMAP user
      # @param [String] imap_password the IMAP password (we are using CRAM-MD5 right now for login)
      # @param [Integer] imap_port the port number on which the IMAP server listens
      # @param [Boolean] imap_ssl true when we have an SSL/TLS connection
      # @throws [ArgumentError] in case the passed params are nil or not Strings
      def initialize(imap_server, imap_user, imap_password, imap_port, imap_ssl)
        raise ArgumentError, "imap_server is supposed to be not nil and of type String" unless !imap_server.nil? && imap_server.instance_of?(String)
        raise ArgumentError, "imap_user is supposed to be not nil and of type String" unless !imap_user.nil? && imap_user.instance_of?(String)
        raise ArgumentError, "imap_password is supposed to be not nil and of type String" unless !imap_password.nil? && imap_password.instance_of?(String)
        raise ArgumentError, "imap_port is supposed to be not nil and of type Integer (got: '#{imap_port.class.to_s}')" unless !imap_port.nil? && imap_port.kind_of?(Integer)
        raise ArgumentError, "imap_ssl is supposed to be not nil and of type Boolean" unless !imap_ssl.nil? && (imap_ssl.instance_of?(TrueClass) || imap_ssl.instance_of?(FalseClass))

        raise FeedMe::FeedMeError, "SSL support not yet available" if imap_ssl

        @logger = FeedMe::Utils::Logger.get(self.class)
        @logged_in = false

        @imap_server = imap_server
        @imap_user = imap_user
        @imap_password = imap_password
        @imap_port = imap_port
        @imap_ssl = imap_ssl
      end

      # Logs in to the IMAP server
      # @throws [FeedMe::ImapException] in case we are already logged in
      # @throws [FeedMe::ImapException] in case we are not able to connect to the IMAP server
      def login
        raise FeedMe::ImapException, "You are already logged in" if @logged_in
        begin
          imap_info = "IMAP server #{@imap_server}:#{@imap_port} with user #{@imap_user}, SSL enabled: #{@imap_ssl.to_s}"
          @logger.info{"Connecting to #{imap_info}"}
          @imap = Net::IMAP.new(@imap_server, @imap_port)
          @imap.authenticate("CRAM-MD5", @imap_user, @imap_password)
          @logger.info{"Successfully connected to IMAP server: #{imap_info}"}
          @logger.debug{"IMAP servers greeting: #{@imap.greeting}"}
          @logged_in = true
        rescue => ex
          @logged_in = false

          msg = "Unable to connect to IMAP server; reason: #{ex.message}$/#{ex.backtrace.join($/)}"
          @logger.warn{msg}
          raise FeedMe::ImapException, msg
        end
      end

      def logout
        raise FeedMe::ImapException, "You are not yet logged in" unless @logged_in

        @imap.logout
        @logged_in = false
      end
    end
  end
end