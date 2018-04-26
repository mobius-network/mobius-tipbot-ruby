class TipBot::Telegram::Service::TipMessage
  class << self
    def call(message, tipper)
      TipBot::User.new(message.from.username).tip
      TipBot::TippedMessage.new(message.message_id).tip(tipper)
    end
  end
end
