require "cgi"

# /register command handler
class TipBot::Telegram::Command::Register < TipBot::Telegram::Command::Base
  def call
    return unless direct_message?
    bot.api.send_message(chat_id: from.id, text: register_address)
  end

  def address
    @address ||= text.split(" ")[1]
  end

  def deposit_amount
    @deposit_amount ||= text.split(" ")[2]
  end

  private

  def register_address
    policy = ::RegisterCommandValidnessPolicy[self]
    return policy.errors.messages.first unless policy.valid?

    say_url
  rescue Mobius::Client::Error::AccountMissing
    say_account_is_missing
  rescue TipBot::Telegram::Service::RegisterAddress::NoTrustlineError
    say_no_trustline
  rescue TipBot::Telegram::Service::RegisterAddress::AddressAlreadyRegisteredError
    say_registered_address
  end

  def say_account_is_missing
    t(:account_missing, address: address)
  end

  def say_no_trustline
    t(:trustline_missing, address: address, code: Mobius::Client.stellar_asset)
  end

  def say_registered_address
    t(:registered_address, address: user.address)
  end

  def say_url
    xdr = TipBot::Telegram::Service::RegisterAddress.call(from.username, address, deposit_amount).to_xdr(:base64)
    url = "https://www.stellar.org/laboratory/#txsigner?xdr=#{CGI.escape(xdr)}&network=#{Mobius::Client.network}"
    t(:register_address_link, url: url)
  end
end
