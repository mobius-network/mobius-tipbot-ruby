# Register address command
class TipBot::Telegram::Service::RegisterAddress
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  class NoTrustlineError < StandardError; end
  class AddressAlreadyRegisteredError < StandardError; end

  param :username
  param :address
  param :deposit_amount

  def call
    raise AddressAlreadyRegisteredError unless user.address.nil?
    raise NoTrustlineError unless provided_stellar_account.trustline_exists?

    {
      user_address: new_random_stellar_account.keypair.address,
      txe: new_account_tx.to_envelope(new_random_stellar_account.keypair)
    }
  end

  private

  def new_random_stellar_account
    @new_random_stellar_account ||= Mobius::Client::Blockchain::Account.new(Stellar::KeyPair.random)
  end

  def provided_stellar_account
    @provided_stellar_account ||= Mobius::Client::Blockchain::Account.new(
      Mobius::Client.to_keypair(address)
    )
  end

  def user
    @user ||= TipBot::User.new(username)
  end

  def new_account_operations
    [
      create_account_op,
      change_trust_op,
      set_options_op,
      add_bot_as_signer_op,
      payment_op
    ]
  end

  def create_account_op
    Stellar::Operation.create_account(
      destination: new_random_stellar_account.keypair,
      starting_balance: 2.5 + 1
    )
  end

  def change_trust_op
    Stellar::Operation.change_trust(
      line: [
        :alphanum4,
        Mobius::Client.stellar_asset.code,
        Mobius::Client.to_keypair(Mobius::Client.stellar_asset.issuer)
      ],
      limit: 922337203685,
      source_account: new_random_stellar_account.keypair
    )
  end

  def set_options_op
    Stellar::Operation.set_options(
      source_account: new_random_stellar_account.keypair,
      high_threshold: 2,
      med_threshold: 1,
      low_threshold: 1,
      master_weight: 0,
      signer: StellarHelpers.to_signer(provided_stellar_account, weight: 2)
    )
  end

  def add_bot_as_signer_op
    Stellar::Operation.set_options(
      source_account: new_random_stellar_account.keypair,
      signer: StellarHelpers.to_signer(TipBot.app_account, weight: 1)
    )
  end

  def payment_op
    Stellar::Operation.payment(
      destination: new_random_stellar_account.keypair,
      amount: StellarHelpers.to_payment_amount(deposit_amount.to_f)
    )
  end

  def new_account_tx
    Stellar::Transaction
      .for_account(
        account: provided_stellar_account.keypair,
        sequence: provided_stellar_account.next_sequence_value,
        fee: 100 * new_account_operations.size
      )
      .tap { |t| t.operations.concat(new_account_operations) }
  end
end
