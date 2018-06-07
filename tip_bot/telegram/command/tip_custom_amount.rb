# /tip <amount> command handler
class TipBot::Telegram::Command::TipCustomAmount < TipBot::Telegram::Command::Base
  def call
    return say_invalid_amount unless amount_is_valid?
  end

  def amount
    @amount ||= text.split(" ")[1]
  end

  private

  def say_invalid_amount
    reply(t(:invalid_amount, amount: amount))
  end

  def amount_is_valid?
    Float(amount).positive?
  rescue ArgumentError
    false
  end

  def command_scope
    %i[telegram cmd tip]
  end
end
