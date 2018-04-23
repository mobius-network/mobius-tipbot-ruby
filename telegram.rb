require "./tip_bot"
require "mobius/client"
require "telegram/bot"

TipBot.configure!

Telegram::Bot::Client.run(TipBot.token, logger: TipBot.logger) do |bot|
  bot.listen do |message|
    TipBot::Telegram::Message.call(bot, message)
  end
end

=begin
TipBot::Telegram.start!(
  ENV["MOBIUS_TIPBOT_TELEGRAM_API_TOKEN"],
  ENV["MOBIUS_TIPBOT_RATE"] || 1,
  Mobius::Client::App.new(
    ENV["MOBIUS_TIPBOT_APP_PRIVATE_KEY"],
    ENV["MOBIUS_TIPBOT_CREDIT_ADDRESS"]
  )
)
=end
# 592205386:AAHjcGbTHyT_ernoV41ayTmKFF4kLTrwsw4
