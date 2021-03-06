require 'rubygems'
require 'bundler/setup'

require "date"
require 'net/imap'

require_relative '../exceptions/imap_exception'
require_relative '../exceptions/feed_me_error'

module FeedMe
  module Processor
    class ImapFacade
      HIERARCHY_DELIMITER = '/'
      FEED_ME_IMAP_HEADER = 'X-Feed-Me-ID'

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
          @imap = Net::IMAP.new(@imap_server, {:port => @imap_port, :ssl => @imap_ssl})
          @imap.authenticate("CRAM-MD5", @imap_user, @imap_password)
          @logger.info{"Successfully connected to IMAP server: #{imap_info}"}
          @logger.debug{"IMAP servers greeting: #{@imap.greeting}"}

          imap_info = @imap.list("", "")[0]
          @logger.info{"IMAP Server information: #{imap_info.inspect}"}
          @imap_delimiter = imap_info.delim
          @logger.info{"Delimiter to use on the IMAP server: '#{@imap_delimiter}'"}

          @logged_in = true
        rescue => ex
          @logged_in = false

          msg = "Unable to connect to IMAP server; reason: #{ex.message}$/#{ex.backtrace.join($/)}"
          @logger.warn{msg}
          raise FeedMe::ImapException, msg
        end
      end

      # Logs out of the IMAP server; you should call this method in case you don't plan any other actions on this IMAP conenction
      # @throws [Feedme::ImapException] in case we are not logged in
      def logout
        raise FeedMe::ImapException, "You are not yet logged in" unless @logged_in

        @imap.logout
        @logged_in = false
      end

      # @return [Boolean] true if logged in, false if not logged in
      def logged_in?
        return @logged_in
      end

      protected
      # Stores an message at the IMAP server in the given folder; in case the folder doesn't exist, it will create this folder
      # We will use the '/' as a hierarchy seperator and map it to the IMAP specific one (e.g. '.', or '/', ...). If your IMAP server uses e.g. '.' as
      # seperator and you pass "Foo.Bar/Baz" it will create a hierarchy as follows: "Foo/Bar/Baz" - there is no easy way around this for the time being
      # @param [String] folder_name the name of the IMAP folder; a '/' in the text indicates a child entry; thus "Foo/bar" is a folder structure Foo/bar
      # @param [String] subject the subject of the email
      # @param [DateTime] time the time we want to set on the email
      # @param [String] body the email body
      # @param [String] msg_id unique ID of this message
      # @throws [ArgumentError] in case we are not yet logged in
      # @throws [FeedMe::ImapException] in case we are not yet logged in
      # @throws [FeedMe::ImapException] in case we encounter any issues creating a message on the server
      def store_message(folder_name, subject, time, body, msg_id)
        raise ArgumentError, "folder_name must not be nil and of type String (got: '#{folder_name.class.to_s}'" unless !folder_name.nil? && folder_name.instance_of?(String)
        raise ArgumentError, "subject must not be nil and of type String (got: '#{subject.class.to_s}'" unless !subject.nil? && subject.instance_of?(String)
        raise ArgumentError, "time must not be nil and of type DateTime (got: '#{time.class.to_s}'" unless !time.nil? && time.instance_of?(DateTime)
        raise ArgumentError, "body must not be nil and of type String (got: '#{body.class.to_s}'" unless !body.nil? && body.instance_of?(String)
        raise ArgumentError, "msg_id must not be nil and of type String (got: '#{msg_id.class.to_s}'" unless !msg_id.nil? && msg_id.instance_of?(String)

        raise FeedMe::ImapException, "You are not yet logged in, please login first" unless @logged_in

        begin
          # it's not absolutely clear to me if *all* IMAP server will create hierarchies on it's own or not, so let's do this
          # on our own in any case
          folder_array = folder_name.split(HIERARCHY_DELIMITER)
          folder_array.each_index do |idx|
            new_folder_name = folder_array[0..idx].join(@imap_delimiter)
            if @imap.list("", new_folder_name)
              @logger.debug{"Folder '#{new_folder_name}' already exists, no need to create it again"}
            else
              @logger.debug{"Trying to create folder: '#{new_folder_name}'"}
              @imap.create(new_folder_name)
              @logger.debug{"Created folder: '#{new_folder_name}'"}
            end
          end

          folder_name_normalized = folder_array.join(@imap_delimiter)
          # let's execute a list on the folder to make sure the folder really exists - if not we will get an exception
          @imap.list("", folder_name_normalized)

          # now we will append the new message to the folder
          msg = create_message(subject, "sender@localhost", "recipient@localhost", time, body, msg_id)
          @imap.append(folder_name_normalized, msg, nil, time.to_time)
        rescue => ex
          msg = "Encountered error while storing message with subject '#{subject}' in the IMAP server: #{ex.message}#{$/}#{ex.backtrace.join($/)}"
          raise FeedMe::ImapException, msg
        end
      end

      # Determines if a message identified by it's FEED_ME_IMAP_HEADER header exists in the given folder
      # @param [String] folder_name then name of the folder where the message is stored
      # @param [String] msg_id the FEED_ME_IMAP_HEADER value to identify the message
      # @throws [ArgumentError] in case the passed parameters are not proper
      # @return [Boolean] true if such a message was found; false if not found
      def message_exists?(folder_name, msg_id)
        raise ArgumentError, "folder_name must be not nil and a String (got: '#{msg_id.class.to_s}')" unless !folder_name.nil? && folder_name.instance_of?(String)
        raise ArgumentError, "msg_id must be not nil and a String (got: '#{msg_id.class.to_s}')" unless !msg_id.nil? && msg_id.instance_of?(String)

        raise FeedMe::ImapException, "You are not yet logged in, please login first" unless @logged_in

        @logger.debug{"Determining if '#{folder_name}' contains message with ID #{msg_id}"}

        # Return with false in case the folder doesn't exist at all
        unless @imap.list("", normalized_folder_name(folder_name))
          @logger.debug{"The folder '#{folder_name}' doesn't exist; thus the message '#{msg_id}' can't exist either"}
          return false
        end

        @imap.select(normalized_folder_name(folder_name))
        search_param = ["HEADER", FEED_ME_IMAP_HEADER,  msg_id]
        @logger.debug{"IMAP search string: #{search_param}"}
        search_result = nil
        begin
          search_result = @imap.search(search_param)
        rescue NoMethodError => ex
          # there seems to be a bug; if no messages are found, then I get a
          #   NoMethodError: undefined method `[]' for nil:NilClass
          # looking into imap.rb it tries to delete the key "SEARCH" from the response which doesn't exist
          # This maybe due to a bug in imap.rb or due to a bug in the IMAP server I use for testing
          # anyway, let's recover from it
          if ex.instance_of?(NoMethodError) && ex.message =~ /\[\].* for nil:NilClass/
            search_result = nil
          else
            # re-raise
            raise ex
          end
        end

        ret_val = !search_result.nil? && search_result.size > 0 ? true : false
        @logger.debug{"Message with ID #{msg_id} found: #{search_result}"}

        return ret_val
      end

      protected
      # Creates an String suiatable for storing the message on the IMAP server
      # @param [String] subject the subject of the message
      # @param [String] from the sender
      # @param [String] to the recipient
      # @param [DateTime] time the time of the message
      # @param [String] body the body of the message
      # @param [String] msg_id unique message ID
      def create_message(subject, from, to, time, body, msg_id)
        ret_val = <<EOS
Subject: #{subject}
From: #{from}
To: #{to}
#{FEED_ME_IMAP_HEADER}: #{msg_id}
Date: #{time.rfc2822}

#{body}
EOS
        ret_val.gsub!(/\r\n?|\n/, "\r\n")

        return ret_val
      end

      private
      # Returns a folder name which uses the server specific delimiter; will only work once logged in
      # @param [String] folder_name the folder name we want to normailize
      # @returns [String] normalized folder name
      def normalized_folder_name(folder_name)
        raise FeedMe::ImapException, "You are not yet logged in" unless @logged_in

        new_folder_name = folder_name.split(HIERARCHY_DELIMITER).join(@imap_delimiter)

        return new_folder_name
      end
    end
  end
end