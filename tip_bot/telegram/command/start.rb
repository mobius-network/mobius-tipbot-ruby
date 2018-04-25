class TipBot::Telegram::Command::Start
  def call
    type = direct_message? ? :private : :public
    text = t(:"start.#{type}", username: from.username)
    bot.api.send_message(chat_id: from.id, text: text)
  end
end
