require "cgi"

# /unregister command handler
class TipBot::Telegram::Command::Unregister < TipBot::Telegram::Command::Base
  def call
    return unless direct_message?

    unregister_address
  rescue Mobius::Client::Error::AccountMissing
    say_account_is_missing
  rescue Mobius::Client::Error::UnknownKeyPairType
    say_address_is_invalid
  rescue TipBot::Telegram::Service::UnregisterAddress::NoTrustlineError
    say_no_trustline
  rescue TipBot::Telegram::Service::UnregisterAddress::NoAddressRegistered
    say_no_address_registered
  end

  def withdraw_address
    @withdraw_address ||= text.split(" ")[1]
  end

  private

  def unregister_address
    return say_address_is_missing if withdraw_address.nil?

    xdr = TipBot::Telegram::Service::UnregisterAddress.call(from.id, withdraw_address)
    url = "https://www.stellar.org/laboratory/#txsigner?xdr=#{CGI.escape(xdr)}&network=#{Mobius::Client.network}"

    bot.api.send_message(
      chat_id: from.id,
      text: t(:unregister_address_link, url: url),
      reply_markup: acknowledge_button
    )
  end

  def say_account_is_missing
    bot.api.send_message(chat_id: from.id, text: t(:account_missing, address: withdraw_address))
  end

  def say_no_trustline
    bot.api.send_message(
      chat_id: from.id,
      text: t(:trustline_missing, address: withdraw_address, code: Mobius::Client.stellar_asset)
    )
  end

  def say_no_address_registered
    bot.api.send_message(chat_id: from.id, text: t(:no_address_registered))
  end

  def say_address_is_missing
    bot.api.send_message(chat_id: from.id, text: t(:withdraw_address_missing))
  end

  def say_address_is_invalid
    bot.api.send_message(chat_id: from.id, text: t(:withdraw_address_invalid))
  end

  def acknowledge_button
    Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [
        Telegram::Bot::Types::InlineKeyboardButton.new(
          text: t(:address_unregister_ack),
          callback_data: "unreg_ack"
        )
      ]
    )
  end
end
