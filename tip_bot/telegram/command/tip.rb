# Tip button press handler
class TipBot::Telegram::Command::Tip < TipBot::Telegram::Command::Base
  def call
    return answer_callback_query(policy.errors.messages.first) unless policy.valid?

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

  def update_tip_menu
    bot.api.edit_message_text(
      message_id: message_id,
      chat_id: chat.id,
      text: button_message.heading_text,
      reply_markup: button_message.button_layout
    )
  end

  def error_insufficient_funds
    bot.api.answer_callback_query(callback_query_id: subject.id, text: t(:insufficient_funds))
  end

  def error_mobius_client(err)
    bot.logger.error err.message
    bot.api.answer_callback_query(callback_query_id: subject.id, text: t(:error))
  end

  def tipped_message
    @tipped_message ||= TipBot::TippedMessage.new(message.reply_to_message)
  end

  def button_message
    @button_message ||= TipBot::TipButtonMessage.new(tipped_message)
  end

  def tipper_user
    @tipper_user ||= TipBot::User.new(subject.from)
  end

  def call_tip_message_and_lock
    TipBot::Telegram::Service::TipMessage.call(
      subject.message.reply_to_message,
      TipBot::User.new(subject.from)
    )
  end

  def policy
    ::TipCommandValidnessPolicy[
      message_to_tip: message.reply_to_message,
      tipper: tipper_user
    ]
  end
end
