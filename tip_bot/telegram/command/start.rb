# /start command handler
class TipBot::Telegram::Command::Start < TipBot::Telegram::Command::Base
  def call
    type = direct_message? ? :private : :public
    text = TipBot.t(type, username: from.username)
    bot.api.send_message(chat_id: chat.id, text: text)
  end
end
