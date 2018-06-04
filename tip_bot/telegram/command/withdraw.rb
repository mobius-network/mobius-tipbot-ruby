# /withdraw command handler
class TipBot::Telegram::Command::Withdraw < TipBot::Telegram::Command::Base
  def call
    return unless direct_message?
    bot.api.send_message(chat_id: from.id, text: reply)
  end

  def address
    @address ||= text.split(" ")[1]
  end

  def amount
    @amount ||= text.split(" ")[2]
  end

  private

  def reply
    policy = ::WithdrawCommandValidnessPolicy[self]
    return policy.errors.messages.first unless policy.valid?

    TipBot::Telegram::Service::Withdraw.call(user, address, amount_to_withdraw)
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
    t(:done, address: address, amount: amount_to_withdraw, asset: Mobius::Client.asset_code)
  end

  def amount_to_withdraw
    @amount_to_withdraw ||= (amount&.to_f || user.balance)
  end
end
