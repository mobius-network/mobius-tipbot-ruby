#!/usr/bin/env ruby

require "bundler/setup"
require "telegram/bot"
require "./tip_bot"

TipBot.configure!

run TipBot::Telegram::WebhookRouter.new
