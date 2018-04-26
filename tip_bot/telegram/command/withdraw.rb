# /withdraw command handler
class TipBot::Telegram::Command::Withdraw < TipBot::Telegram::Command::Base
  def call
    return unless direct_message?
    bot.api.send_message(chat_id: from.id, text: reply)
  end

  private

  def reply
    return t(:address_missing) if address.nil?
    return t(:nothing) if user.balance.zero?
    user.withdraw(address)
    t(:done, address: address)
  rescue Mobius::Client::Error::UnknownKeyPairType
    t(:invalid_address, address: address)
  end

  def address
    @address ||= text.split(" ")[1]
  end
end
