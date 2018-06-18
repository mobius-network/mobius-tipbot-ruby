# Service, performing money withdrawal from user's account
class TipBot::Telegram::Service::Withdraw
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  param :user
  param :destination_address
  param :amount

  def call
    if user.stellar_account.nil?
      TipBot.dapp.payout(amount, target_address: destination_address)
      user.decrement_balance(amount)
    else
      withdraw_from_user_account
    end

    amount
  end

  private

  def withdraw_from_user_account
    user.transfer_money(amount, destination_address)
  end
end
