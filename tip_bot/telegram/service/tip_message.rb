# Service, performing actual tipping
# Transfers money to the author of the message been tipped,
# and increase overall balance of that message
class TipBot::Telegram::Service::TipMessage
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  # @!method initialize(seed)
  # @param message [Telegram::Bot::Types::Message] Message to be tipped
  # @param tipper_nickname [String] Telegram username of a tipper
  # @!scope instance
  param :message
  param :tipper_nickname

  def call
    return if tipper.locked?
    tip
    tipper.lock
  end

  private

  def message_author
    @message_author ||= TipBot::User.new(message.from.username)
  end

  def tipper
    @tipper ||= TipBot::User.new(tipper_nickname)
  end

  def tip
    value = TipBot.tip_rate
    dapp.pay(value, target_address: message_author.address)
    message_author.increment_balance(value) unless message_author.address
    TipBot::TippedMessage.new(message).tip(tipper_nickname)
  end

  def dapp
    if tipper.address.nil?
      TipBot.dapp
    else
      Mobius::Client::App.new(TipBot.dapp.seed, tipper.address)
    end
  end
end
