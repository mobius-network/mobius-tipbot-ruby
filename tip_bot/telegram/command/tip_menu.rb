# /tip command handler
class TipBot::Telegram::Command::TipMenu < TipBot::Telegram::Command::Base
  def call
    return if tip_not_allowed?

    TipBot::Telegram::Service::TipMessage.call(reply_to_message, username)

    api.send_message(
      chat_id: chat.id,
      text: tip_heading,
      reply_to_message_id: reply_to_message.message_id,
      reply_markup: TipBot::Telegram::TipKbMarkup.call(tipped_message.count)
    )
  end

  private

  # We can not tip bots, man himself and show standalone tipping menu
  def tip_not_allowed?
    reply_to_message.nil? ||
      reply_to_message.from.id == from.id ||
      from.is_bot ||
      empty_username? ||
      tipped_message.tipped?(username)
  end

  def tip_heading
    t(
      :heading,
      usernames: "@#{message.from.username}",
      count: 1,
      amount: tipped_message.balance,
      scope: %i(telegram tip)
    )
  end

  def tipped_message
    @tipped_message ||= TipBot::TippedMessage.new(reply_to_message.message_id)
  end
end
