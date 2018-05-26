#!/usr/bin/env ruby

require "bundler/setup"
require "telegram/bot"
require "./tip_bot"

$stdout.sync = true

TipBot.configure!

run TipBot::Telegram::WebhookRouter.new
