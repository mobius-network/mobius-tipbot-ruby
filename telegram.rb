require "./tip_bot"
require "telegram/bot"

TipBot.configure!

Telegram::Bot::Client.run(TipBot.token, logger: TipBot.logger) do |bot|
  bot.listen do |message|
    TipBot::Telegram::Message.call(bot, message)
  end
end
