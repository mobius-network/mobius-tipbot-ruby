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

  def error_insufficient_funds
    reply(t(:insufficient_funds))
  end

  def handle_already_tipped_message
    return forward_existing_keyboard if amount.nil?
  end

  def forward_existing_keyboard
    reply(
      t(
        :already_tipped_message,
        link: "t.me/#{chat.username}/#{tipped_message.button_message_id}"
      )
    )
  end

  def send_tip_button
    response = api.send_message(
      chat_id: chat.id,
      text: tip_heading,
      reply_to_message_id: reply_to_message.message_id,
      reply_markup: TipBot::Telegram::TipKbMarkup.call(tipped_message.count)
    )
    tipped_message.attach_button(response.dig("result", "message_id"))
  end

  def message_already_tipped?
    tipped_message.count.positive?
  end

  def tip_heading
    t(
      :heading,
      usernames: "@#{message.from.username}",
      count: 1,
      amount: tipped_message.balance,
      recipient: tipped_message.author.display_name,
      recipient_total: tipped_message.author.balance
    )
  end

  def tipped_message
    @tipped_message ||= TipBot::TippedMessage.new(reply_to_message)
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
