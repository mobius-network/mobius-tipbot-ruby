# /balance command handler
class TipBot::Telegram::Command::Balance < TipBot::Telegram::Command::Base
  def call
    return unless direct_message?
    bot.api.send_message(chat_id: from.id, text: reply)
  end

  private

  def reply
    return t(:linked, address: user.address) if user.address
    t(:value, balance: user.balance)
  end
end
