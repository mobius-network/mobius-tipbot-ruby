require "./tip_bot"
require "mobius/client"

TipBot.configure!
TipBot.redis = Redis.new(url: ENV["MOBIUS_TIPBOT_REDIS_URL"])
TipBot::Telegram.start!(
  ENV["MOBIUS_TIPBOT_TELEGRAM_API_TOKEN"],
  ENV["MOBIUS_TIPBOT_RATE"] || 1,
  Mobius::Client::App.new(
    ENV["MOBIUS_TIPBOT_APP_PRIVATE_KEY"],
    ENV["MOBIUS_TIPBOT_CREDIT_ADDRESS"]
  )
)

# 592205386:AAHjcGbTHyT_ernoV41ayTmKFF4kLTrwsw4
