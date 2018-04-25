class TipBot::Telegram::Command::TipMenu < TipBot::Telegram::Command::Base
  def call
    return if tip_not_allowed?
    bot.api.send_message(
      chat_id: chat.id,
      text: tip_heading,
      reply_to_message_id: message_id,
      reply_markup: TipBot::Telegram::TipKbMarkup.call(0)
    )
  end

  private

  # We can not tip bots, man himself and show standalone tipping menu
  def tip_not_allowed?
    message.reply_to_message.nil? ||
      message.reply_to_message.from.id == from.id ||
      false # from.is_bot DEBUG
  end

  def tip_heading
    t(:heading, username: message.reply_to_message.from.username, amount: 0, scope: %i(telegram tip))
  end
end
