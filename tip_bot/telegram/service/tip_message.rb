# Service, performing actual tipping
# Transfers money to the author of the message been tipped,
# and increase overall balance of that message
class TipBot::Telegram::Service::TipMessage
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  class CustomAmountTipWithoutBalanceError < StandardError; end

  # @!method initialize(seed)
  # @param message [Telegram::Bot::Types::Message] Message to be tipped
  # @param tipper_user [TipBot::User] tipper
  # @param amount [Float] amount of money to tip
  # @!scope instance
  param :message
  param :tipper
  param :amount, optional: true

  def call
    return if tipper.locked?
    raise CustomAmountTipWithoutBalanceError if amount && tipper.balance <= tip_amount

    tip
  rescue Mobius::Client::Error::InsufficientFunds
    BalanceAlertJob.perform_async(:exhausted)
    raise
  end

  private

  def message_author
    @message_author ||= TipBot::User.new(message.from)
  end

  def tip
    if tipper.funded_address?
      tip_via_user_account
    else
      tip_via_dapp
    end

    TipBot::TippedMessage.new(message).tip(tipper.username, amount)
  end

  def tip_via_dapp
    if message_author.address
      tip_via_dapp_to_address(message_author.address)
    else
      tip_via_dapp_inside
    end

    TipBot.check_balance
  end

  def tip_via_dapp_to_address(address)
    if tipper.balance >= tip_amount
      TipBot.dapp.payout(tip_amount, target_address: address)
      tipper.decrement_balance(tip_amount)
    else
      TipBot.dapp.charge(tip_amount, target_address: address)
      tipper.lock
    end
  end

  def tip_via_dapp_inside
    if tipper.balance >= tip_amount
      tipper.transfer_from_balance(tip_amount, message_author)
    else
      TipBot.dapp.charge(tip_amount)
      message_author.increment_balance(tip_amount)
      tipper.lock
    end
  end

  def tip_via_user_account
    destination = message_author.address || TipBot.app_keypair.address
    tipper.transfer_money(tip_amount, destination)
    message_author.increment_balance(tip_amount) if message_author.address.nil?
  end

  def tip_amount
    amount || TipBot.config.rate
  end
end
