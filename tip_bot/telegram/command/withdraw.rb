# /withdraw command handler
class TipBot::Telegram::Command::Withdraw < TipBot::Telegram::Command::Base
  def call
    return unless direct_message?
    bot.api.send_message(chat_id: from.id, text: reply)
  end

  private

  def reply
    return say_address_missing if address.nil?
    return say_nothing_to_withdraw if user.balance.zero?
    user.withdraw(address)
    say_done
  rescue Mobius::Client::Error::TrustlineMissing
    say_trustline_missing
  rescue Mobius::Client::Error::AccountMissing
    say_account_missing
  rescue Mobius::Client::Error::UnknownKeyPairType
    say_invalid_address
  end

  def say_trustline_missing
    t(:trustline_missing, address: address, code: Mobius::Client.asset_code, issuer: Mobius::Client.asset_issuer)
  end

  def say_account_missing
    t(:account_missing, address: address)
  end

  def say_invalid_address
    t(:invalid_address, address: address)
  end

  def say_done
    t(:done, address: address)
  end

  def say_address_missing
    t(:address_missing)
  end

  def say_nothing_to_withdraw
    t(:nothing)
  end

  def address
    @address ||= text.split(" ")[1]
  end
end
