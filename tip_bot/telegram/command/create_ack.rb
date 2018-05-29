class TipBot::Telegram::Command::CreateAck < TipBot::Telegram::Command::Base
  def call
    return address_is_not_funded unless new_address_is_funded?

    user.address = new_user_address
    user.merge_balances

    bot.api.send_message(
      chat_id: message.chat.id,
      text: t(:all_set, new_address: user.address)
    )
  end

  private

  def address_is_not_funded
    bot.api.send_message(chat_id: message.chat.id, text: t(:not_funded))
  end

  def new_address_is_funded?
    Mobius::Client::Blockchain::Account.new(
      Stellar::KeyPair.from_address(new_user_address)
    ).balance.positive?
  rescue Mobius::Client::Error::AccountMissing
    false
  end

  def new_user_address
    subject.data.split(":").last
  end

  def user
    @user ||= TipBot::User.new(subject.from.username)
  end
end
