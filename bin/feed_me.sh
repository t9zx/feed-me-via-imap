#!/bin/bash -e

# http://stackoverflow.com/questions/630372/determine-the-path-of-the-executing-bash-script
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolute and normalized
if [ -z "$MY_PATH" ] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  echo "Can't determine the directory the script is stored in"
  exit 1
fi

ruby -I$MY_PATH/../lib -e "require 'feed_me/feed_me'; FeedMe::FeedMeNow.new" $1
