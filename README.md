feed-me-via-imap
================

Reads ATOM/RSS feeds and stores them on an IMAP server so that multiple devices can be syncronized.

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
