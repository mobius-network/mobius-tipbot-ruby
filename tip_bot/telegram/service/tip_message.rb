# Service, performing actual tipping
# Transfers many to the author of the message been tipped,
# and increase overall balance of that message
class TipBot::Telegram::Service::TipMessage
  class << self
    def call(message, tipper)
      TipBot::User.new(message.from.username).tip
      TipBot::TippedMessage.new(message.message_id).tip(tipper)
    end
  end
end
