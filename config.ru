#!/usr/bin/env ruby
$LOAD_PATH.unshift ::File.expand_path(::File.dirname(__FILE__) + "/lib")
require "github-trello/server"
$stdout.sync = true
use Rack::ShowExceptions
run GithubTrello::Server.new