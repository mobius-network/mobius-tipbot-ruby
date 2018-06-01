# /tip command handler
class TipBot::Telegram::Command::TipMenu < TipBot::Telegram::Command::Base
  def call
    return if tip_not_allowed?
    return can_not_tip_often if user.locked?
    return forward_existing_keyboard if message_already_tipped?

    TipBot::Telegram::Service::TipMessage.call(reply_to_message, username)

    send_tip_button
  end

  private

  def forward_existing_keyboard
    api.send_message(
      chat_id: chat.id,
      text: t(
        :already_tipped_message,
        link: "t.me/#{chat.username}/#{tipped_message.button_message_id}"
      )
    )
  end

  def can_not_tip_often
    api.send_message(
      chat_id: chat.id,
      text: t(:can_not_tip_often),
      reply_to_message_id: message.message_id
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

  # We can not tip bots, man himself and show standalone tipping menu
  def tip_not_allowed?
    reply_to_message.nil? ||
      reply_to_message.from.id == from.id ||
      tipped_message.tipped?(username) ||
      reply_to_message.from.is_bot ||
      empty_username?
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
      asset: Mobius::Client.asset_code
    )
  end

  def tipped_message
    @tipped_message ||= TipBot::TippedMessage.new(reply_to_message)
  end

  def command_scope
    %i[telegram cmd tip]
  end
end
