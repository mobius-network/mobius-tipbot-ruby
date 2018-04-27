# Tip button press handler
class TipBot::Telegram::Command::Tip < TipBot::Telegram::Command::Base
  def call
    return can_not_tip_twice if tip_message.tipped?(username)
    return can_not_tip_yourself if message.reply_to_message.from.id == subject.from.id

    return if empty_username?

    TipBot::Telegram::Service::TipMessage.call(subject.message.reply_to_message, username)

    update_tip_menu
  rescue Mobius::Client::Error::InsufficientFunds
    error_insufficient_funds
  rescue Mobius::Client::Error => e
    error_mobius_client(e)
  end

  private

  def username
    subject.from.username
  end

  def can_not_tip_twice
    bot.api.answer_callback_query(callback_query_id: subject.id, text: t(:can_not_tip_twice))
  end

  def can_not_tip_yourself
    bot.api.answer_callback_query(callback_query_id: subject.id, text: t(:can_not_tip_yourself))
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
    all_tippers = tip_message.all_tippers.map { |nick| "@#{nick}" }

    if all_tippers.size > 3
      t(
        :heading_for_many_tippers,
        usernames: all_tippers.last(3).join(", "),
        amount: tip_message.balance,
        more: all_tippers.size - 3,
        scope: %i(telegram tip)
      )
    else
      t(
        :heading,
        usernames: all_tippers.join(", "),
        amount: tip_message.balance,
        count: all_tippers.size,
        scope: %i(telegram tip)
      )
    end
  end

  def tip_message
    @tip_message ||= TipBot::TippedMessage.new(message.reply_to_message.message_id)
  end

  def user
    @user ||= TipBot::User.new(message.reply_to_message.from.username)
  end
end
