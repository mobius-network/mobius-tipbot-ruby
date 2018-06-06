class TipBot::Telegram::Command::UnregisterAck < TipBot::Telegram::Command::Base
  def call
    return not_merged unless user_address_is_merged?

    user.address = nil

    bot.api.send_message(
      chat_id: message.chat.id,
      text: t(:merged, new_address: user.address)
    )
  end

  private

  def not_merged
    bot.api.send_message(chat_id: message.chat.id, text: t(:not_merged))
  end

  def user_address_is_merged?
    # This will trigger error on deleted address
    Mobius::Client::Blockchain::Account.new(
      Stellar::KeyPair.from_address(user.address)
    ).balance
    false
  rescue Mobius::Client::Error::AccountMissing
    true
  end

  def user
    @user ||= TipBot::User.new(subject.from)
  end
end
