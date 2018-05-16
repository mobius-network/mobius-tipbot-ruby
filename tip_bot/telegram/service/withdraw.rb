# Service, performing money withdrawal from user's account
class TipBot::Telegram::Service::Withdraw
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  param :user
  param :destination_address
  param :amount, reader: false

  def call
    if user.stellar_account.nil?
      TipBot.dapp.transfer(amount_to_withdraw, destination_address)
      user.decrement_balance(amount_to_withdraw)
    else
      withdraw_from_user_account
    end

    amount_to_withdraw
  end

  private

  def amount_to_withdraw
    @amount_to_withdraw ||= (@amount || user.balance)
  end

  def withdraw_from_user_account
    StellarHelpers.transfer(
      from: user.stellar_account,
      to: destination_address,
      amount: amount_to_withdraw
    )
  end
end
