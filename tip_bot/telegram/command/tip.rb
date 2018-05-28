# Tip button press handler
class TipBot::Telegram::Command::Tip < TipBot::Telegram::Command::Base
  def call
    return can_not_tip_twice if already_tipped?
    return can_not_tip_yourself if himself?
    return can_not_tip_often if locked?
    return if empty_username?

    call_tip_message_and_lock
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

  def locked?
    tipper_user.locked?
  end

  def himself?
    message.reply_to_message.from.id == subject.from.id
  end

  def already_tipped?
    tipped_message.tipped?(username)
  end

  def can_not_tip_twice
    bot.api.answer_callback_query(callback_query_id: subject.id, text: t(:can_not_tip_twice))
  end

  def can_not_tip_yourself
    bot.api.answer_callback_query(callback_query_id: subject.id, text: t(:can_not_tip_yourself))
  end

  def can_not_tip_often
    bot.api.answer_callback_query(callback_query_id: subject.id, text: t(:can_not_tip_often))
  end

  def update_tip_menu
    bot.api.edit_message_text(
      message_id: message_id,
      chat_id: chat.id,
      text: tip_heading,
      reply_markup: TipBot::Telegram::TipKbMarkup.call(tipped_message.count)
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
    all_tippers.size > 3 ? say_many_tippers : say_tippers
  end

  def all_tippers
    @all_tippers ||= tipped_message.all_tippers.map { |nick| "@#{nick}" }
  end

  def say_many_tippers
    t(
      :heading_for_many_tippers,
      usernames: all_tippers.last(3).join(", "),
      amount: tipped_message.balance,
      more: all_tippers.size - 3,
      asset: Mobius::Client.asset_code
    )
  end

  def say_tippers
    t(
      :heading,
      usernames: all_tippers.join(", "),
      amount: tipped_message.balance,
      asset: Mobius::Client.asset_code
    )
  end

  def tipped_message
    @tipped_message ||= TipBot::TippedMessage.new(message.reply_to_message)
  end

  def user
    @user ||= TipBot::User.new(message.reply_to_message.from.username)
  end

  def tipper_user
    @tipper_user ||= TipBot::User.new(username)
  end

  def call_tip_message_and_lock
    TipBot::Telegram::Service::TipMessage.call(subject.message.reply_to_message, username)
  end
end
