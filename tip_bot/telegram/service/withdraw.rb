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
      post_tx(transfer_txe)
    end

    amount_to_withdraw
  end

  private

  def transfer_txe
    Stellar::Transaction
      .payment(
        account: user.stellar_account.keypair,
        sequence: user.stellar_account.next_sequence_value,
        destination: Mobius::Client.to_keypair(destination_address),
        amount: StellarHelpers.to_payment_amount(amount_to_withdraw)
      )
      .to_envelope(TipBot.app_keypair)
      .to_xdr(:base64)
  end

  def post_tx(txe)
    Mobius::Client.horizon_client.horizon.transactions._post(tx: txe)
  end

  def amount_to_withdraw
    @amount_to_withdraw ||= (@amount || user.balance)
  end
end
