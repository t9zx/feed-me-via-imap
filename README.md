feed-me-via-imap
================

Reads ATOM/RSS feeds and stores them on an IMAP server so that multiple devices can be syncronized.

Why would you want to use such a thing? Here is my story: I'm reading a couple of dozen feeds on different platforms
(mobile, tablet, laptop, workstation, ...). In the past I had on each device some RSS reader installed. Due to different
platforms it was not that easy to have the read/unread state (this is what is most interesting to me) synchronized between
those devices. I could have opted for some online web based RSS reader - but they didn't appeal that much to me (and they are
only available when being online). This was when feed-me-via-imap was born. A Ruby program, which scans feeds, extracts some basic
information and stores them on an IMAP server in a folder for that very feed. Now I can simply use any E-Mail client
supporting IMAP (e.g. Thunderbird) to connect to the mail server and scan my feeds, the read/unread state is handled by the email client
and the IMAP server. Any goodies offered by the email client (tagging, sorting, filtering, ...) can be used on the feed items.

Right now you are looking at version 1.0.0 which is still a little rough and has it glitches - it's good enough for me though :)

This program runs on one of my "always on" machines and is started every hour.

Installation Instructions
=========================

* Install RVM (https://rvm.io/) with Ruby 2.0.0
  * rvm install 2.0.0
  * rvm gemset create feed-me-via-imap
  * rvm 2.0.0@feed-me-via-imap
* Install Bundler
  * gem install bundler -v "1.3.5"
  * bundle install

Usage
=====

Setup a config file, use `conf/config_template.yaml` as an example.

Then call from the command line

`bin/feed_me.sh <CONFIG_FILE>`

This will
* read the feeds you configured
* will store them on the IMAP server

GIT Branching Strategy
======================

This projects uses the following branching strategy: http://nvie.com/posts/a-successful-git-branching-model/

Caveats
=======

* We will use the '/' as a hierarchy seperator and map it to the IMAP specific one (e.g. '.', or '/', ...). If your IMAP server uses e.g. '.' as seperator and you pass "Foo.Bar/Baz" it will create a hierarchy as follows: "Foo/Bar/Baz" - there is no easy way around this for the time being
* Mailbox names are not converted to UTF-7
* Handling of special characters (e.g. German umlauts) are not properly handled in the message body
* HTML formatted feed information is shown as plain text in the message

Version History
===============

1.0.0: Initial version
* Feeds are synced
* Config file support
