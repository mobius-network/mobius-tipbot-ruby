# /start command handler
class TipBot::Telegram::Command::Start < TipBot::Telegram::Command::Base
  def call
    type = direct_message? ? :private : :public
    text = t(type, username: from.username, tip_rate: TipBot.tip_rate)
    bot.api.send_message(chat_id: chat.id, text: text)
  end
end
