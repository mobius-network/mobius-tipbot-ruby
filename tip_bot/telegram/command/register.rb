require "cgi"

class TipBot::Telegram::Command::Register < TipBot::Telegram::Command::Base
  def call
    return unless direct_message?
    bot.api.send_message(chat_id: from.id, text: register_address)
  end

  private

  def register_address
    xdr = TipBot::Telegram::Service::RegisterAddress.call(from.username, address, deposit_amount)
    "https://www.stellar.org/laboratory/#txsigner?xdr=#{CGI.escape(xdr)}&network=#{Mobius::Client.network}"
  rescue Mobius::Client::Error::AccountMissing
    say_account_is_missing
  rescue TipBot::Telegram::Service::RegisterAddress::NoTrustlineError
    say_no_trustline
  end

  def address
    @address ||= text.split(" ")[1]
  end

  def deposit_amount
    @deposit_amount ||= text.split(" ")[2]
  end

  def say_account_is_missing
    "Account #{address} is missing"
  end

  def say_no_trustline
    "No trustline for #{Mobius::Client.stellar_asset}"
  end
end
