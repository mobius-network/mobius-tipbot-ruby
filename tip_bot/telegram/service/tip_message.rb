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
    if tipper.stellar_account.nil?
      tip_via_dapp
    else
      tip_via_user_account
    end

    message_author.increment_balance(tip_amount) unless message_author.address
    TipBot::TippedMessage.new(message).tip(tipper_nickname)
  end

  def tip_via_dapp
    TipBot.dapp.pay(tip_amount, target_address: message_author.address)
  end

  def tip_via_user_account
    destination = message_author.address || TipBot.app_keypair.address
    StellarHelpers.transfer(
      from: tipper.stellar_account,
      to: destination,
      amount: tip_amount
    )
  end

  def tip_amount
    TipBot.tip_rate
  end
end
