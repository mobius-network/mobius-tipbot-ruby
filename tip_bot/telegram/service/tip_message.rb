# Service, performing actual tipping
# Transfers many to the author of the message been tipped,
# and increase overall balance of that message
class TipBot::Telegram::Service::TipMessage
  class << self
    def call(message, tipper)
      user = TipBot::User.new(message.from.username)
      (user.tip && user.lock) unless user.locked?
      TipBot::TippedMessage.new(message).tip(tipper)
    end
  end
end
