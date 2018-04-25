class TipBot::Telegram::Command::Start < TipBot::Telegram::Command::Base
  def call
    type = direct_message? ? :private : :public
    text = t(type, username: from.username)
    bot.api.send_message(chat_id: from.id, text: text)
  end
end
