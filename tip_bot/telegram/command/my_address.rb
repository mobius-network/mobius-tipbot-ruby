class TipBot::Telegram::Command::MyAddress < TipBot::Telegram::Command::Base
  def call
    return unless direct_message?
    bot.api.send_message(chat_id: from.id, text: reply)
  end

  private

  def reply
    return say_no_registered_account if user.address.nil?

    t(:registered_address, address: user.address)
  end

  def say_no_registered_account
    t(:address_is_not_registered)
  end
end
