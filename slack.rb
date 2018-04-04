require "./tip_bot"
require "mobius/client"

TipBot.redis = Redis.new(url: ENV["MOBIUS_TIPBOT_REDIS_URL"])
TipBot::Slack.start!(
  ENV["MOBIUS_TIPBOT_SLACK_API_TOKEN"],
  ENV["MOBIUS_TIPBOT_RATE"] || 1,
  Mobius::Client::App.new(
    ENV["MOBIUS_TIPBOT_APP_PRIVATE_KEY"],
    ENV["MOBIUS_TIPBOT_CREDIT_ADDRESS"]
  )
)
