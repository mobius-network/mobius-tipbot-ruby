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

    withdrawn_amount = TipBot::Telegram::Service::Withdraw.call(user, address, amount&.to_f)
    say_done(withdrawn_amount)
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

  def say_done(withdrawn_amount)
    t(:done, address: address, amount: withdrawn_amount, asset: Mobius::Client.asset_code)
  end

  def say_nothing_to_withdraw
    t(:nothing)
  end
end
