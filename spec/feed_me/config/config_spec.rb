require_relative "../../../lib/feed_me/config/config"

module FeedMe
  module Config
    describe Config do

      let(:config) { <<EOS
imap:
  server: imap_server
  user: imap_user
  password: imap_password

feeds:
  -
    url: http://localhost:1234/foo
    storage: Parent.Child.Child1
  -
    url: http://localhost:1234/bar
    storage: Parent.Child.Child2

foo2:
  nothing: special
EOS
      }

      it "can be instantiated" do
        expect {
          FeedMe::Config::Config.new(StringIO.new(config))
        }.to_not raise_error
      end

      it "allows to retrieve the imap information" do
        c = FeedMe::Config::Config.new(StringIO.new(config))
        expect(c.value("imap.server")).to eq("imap_server")
        expect(c.value("imap.user")).to eq("imap_user")
        expect(c.value("imap.password")).to eq("imap_password")
      end

      it "allows to retrieve the feed information" do
        c = FeedMe::Config::Config.new(StringIO.new(config))
        expect(c.value("feeds")).to be_an(Array)
        expect(c.value("feeds")[0]['url']).to eq("http://localhost:1234/foo")
        expect(c.value("feeds")[0]['storage']).to eq("Parent.Child.Child1")
        expect(c.value("feeds")[1]['url']).to eq("http://localhost:1234/bar")
        expect(c.value("feeds")[1]['storage']).to eq("Parent.Child.Child2")
      end

      it "will raise an error when the key is not a String" do
        c = FeedMe::Config::Config.new(StringIO.new(config))
        expect{ c.value(1) }.to raise_error(ArgumentError)
      end

      context "when incorrect information is given" do
        it "will raise an exception on an empty key" do
          c = FeedMe::Config::Config.new(StringIO.new(config))
          expect{ c.value("") }.to raise_error(FeedMe::Config::ConfigKeyNotFoundError)
        end

        it "will raise an exception on an unknown key" do
          c = FeedMe::Config::Config.new(StringIO.new(config))
          expect{ c.value("foo") }.to raise_error(FeedMe::Config::ConfigKeyNotFoundError)
          expect{ c.value("foo2.bar") }.to raise_error(FeedMe::Config::ConfigKeyNotFoundError)
        end
      end

    end
  end
end