require "cgi"

# /create command handler
class TipBot::Telegram::Command::Create < TipBot::Telegram::Command::Base
  def call
    return unless direct_message?
    bot.api.send_message(chat_id: from.id, text: register_address, reply_markup: acknowledge_button)
  rescue Mobius::Client::Error::AccountMissing
    say_account_is_missing
  rescue TipBot::Telegram::Service::CreateAddress::NoTrustlineError
    say_no_trustline
  rescue TipBot::Telegram::Service::CreateAddress::AddressAlreadyCreatedError
    say_registered_address
  rescue Mobius::Client::Error::UnknownKeyPairType
    say_invalid_address
  end

  def address
    @address ||= text.split(" ")[1]
  end

  def deposit_amount
    @deposit_amount ||= text.split(" ")[2]
  end

  private

  def register_address
    policy = ::CreateCommandValidnessPolicy[self]
    return policy.errors.messages.first unless policy.valid?

    say_url
  end

  def say_account_is_missing
    bot.api.send_message(chat_id: from.id, text: t(:account_missing, address: address))
  end

  def say_no_trustline
    bot.api.send_message(
      chat_id: from.id,
      text: t(:trustline_missing, address: address, code: Mobius::Client.stellar_asset)
    )
  end

  def say_registered_address
    bot.api.send_message(
      chat_id: from.id,
      text: t(:registered_address, address: user.address)
    )
  end

  def say_url
    xdr = txe_to_sign.to_xdr(:base64)
    url = "https://www.stellar.org/laboratory/#txsigner?xdr=#{CGI.escape(xdr)}&network=#{Mobius::Client.network}"
    t(:register_address_link, url: url)
  end

  def say_invalid_address
    t(:invalid_address, address: address)
  end

  def acknowledge_button
    Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [
        Telegram::Bot::Types::InlineKeyboardButton.new(
          text: t(:address_register_ack),
          callback_data: "reg_ack:#{new_user_address}" # we've got limit in 64 bytes here
        )
      ]
    )
  end

  def new_user_address
    service_call[:user_address]
  end

  def txe_to_sign
    service_call[:txe]
  end

  def service_call
    @service_call ||= TipBot::Telegram::Service::CreateAddress.call(from.username, address, deposit_amount)
  end
end
