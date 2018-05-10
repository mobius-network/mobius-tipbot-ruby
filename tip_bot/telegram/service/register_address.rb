class TipBot::Telegram::Service::RegisterAddress
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  class NoTrustlineError < StandardError; end

  param :username
  param :address
  param :deposit_amount

  def call
    raise NoTrustlineError unless user_stellar_account.trustline_exists?

    user.address ||= new_random_stellar_account.keypair.address

    transfer_tx.to_envelope.to_xdr(:base64)
  end

  private

  def new_random_stellar_account
    @new_random_stellar_account ||= Mobius::Client::Blockchain::Account.new(Stellar::KeyPair.random).tap do |acc|
      Mobius::Client::FriendBot.call(acc.keypair.seed, 0)
      bot_app_keypair = Mobius::Client.to_keypair(TipBot.dapp.seed)
      Mobius::Client::Blockchain::AddCosigner.call(acc.keypair, bot_app_keypair)
    end
  end

  def provided_stellar_account
    @provided_stellar_account ||= Mobius::Client::Blockchain::Account.new(
      Mobius::Client.to_keypair(address)
    )
  end

  def user_stellar_account
    @user_stellar_account ||=
      user.address &&
      Mobius::Client::Blockchain::Account.new(
        Mobius::Client.to_keypair(user.address)
      )
  end

  def user
    @user ||= TipBot::User.new(username)
  end

  def transfer_tx
    Stellar::Transaction.for_account(
      account: provided_stellar_account.keypair,
      sequence: provided_stellar_account.next_sequence_value
    ).tap do |t|
      t.operations << Stellar::Operation.payment(
        destination: user_stellar_account.keypair,
        amount: Stellar::Amount.new(deposit_amount.to_f, Mobius::Client.stellar_asset).to_payment
      )
    end
  end
end
