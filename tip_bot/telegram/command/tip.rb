class TipBot::Telegram::Command::Tip < TipBot::Telegram::Command::Base
  def call
    return can_not_tip_twice if tip_message.tipped?(from.username)

    user.tip
    tip_message.tip(from.username)

    update_tip_menu
  rescue Mobius::Client::Error::InsufficientFunds
    error_insufficient_funds
  rescue Mobius::Client::Error => e
    error_mobius_client(e)
  end

  private

  def can_not_tip_twice
    bot.api.answer_callback_query(callback_query_id: subject.id, text: t(:can_not_tip_twice))
  end

  def update_tip_menu
    bot.api.edit_message_text(
      message_id: message_id,
      chat_id: chat.id,
      text: tip_heading,
      reply_markup: TipBot::Telegram::TipKbMarkup.call(tip_message.count)
    )
  end

  def error_insufficient_funds
    bot.api.answer_callback_query(callback_query_id: subject.id, text: t(:insufficient_funds))
  end

  def error_mobius_client(err)
    bot.logger.error err.message
    bot.api.answer_callback_query(callback_query_id: subject.id, text: t(:error))
  end

  def tip_heading
    t(:heading, username: message.reply_to_message.from.username, amount: tip_message.balance, scope: %i(telegram tip))
  end

  def tip_message
    @tip_message ||= TipBot::TipMessage.new(message_id)
  end
end
