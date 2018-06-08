# /tip <amount> command handler
class TipBot::Telegram::Command::TipMenu < TipBot::Telegram::Command::Base
  def call
    return reply(policy.errors.messages.first) unless policy.valid?
    return handle_already_tipped_message if message_already_tipped?

    call_service
    send_tip_button
  rescue Mobius::Client::Error::InsufficientFunds
    error_insufficient_funds
  end

  def amount
    @amount ||= text.split(" ")[1]
  end

  private

  def update_tip_menu
    bot.api.edit_message_text(
      message_id: tipped_message.button_message_id,
      chat_id: chat.id,
      text: button_message.heading_text,
      reply_markup: button_message.button_layout
    )
  end

  def error_insufficient_funds
    reply(t(:insufficient_funds))
  end

  def handle_already_tipped_message
    return forward_existing_keyboard if amount.nil?

    call_service
    update_tip_menu
    reply(t(:tip_accepted, link: button_message_link))
  end

  def forward_existing_keyboard
    reply(t(:already_tipped_message, link: button_message_link))
  end

  def button_message_link
    "t.me/#{chat.username}/#{tipped_message.button_message_id}".freeze
  end

  def send_tip_button
    response = api.send_message(
      chat_id: chat.id,
      text: button_message.heading_text,
      reply_to_message_id: reply_to_message.message_id,
      reply_markup: button_message.button_layout
    )
    tipped_message.attach_button(response.dig("result", "message_id"))
  end

  def message_already_tipped?
    tipped_message.count.positive?
  end

  def tipped_message
    @tipped_message ||= TipBot::TippedMessage.new(reply_to_message)
  end

  def button_message
    @button_message ||= TipBot::TipButtonMessage.new(tipped_message)
  end

  def command_scope
    %i[telegram cmd tip]
  end

  def call_service
    TipBot::Telegram::Service::TipMessage.call(reply_to_message, user, amount&.to_f)
  end

  def policy
    ::TipCommandValidnessPolicy[
      amount: amount,
      message_to_tip: reply_to_message,
      tipper: user
    ]
  end
end
