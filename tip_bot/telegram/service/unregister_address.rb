require "cgi"
# Service for performing actual work for /unregister command
class TipBot::Telegram::Service::UnregisterAddress
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  class NoTrustlineError < StandardError; end
  class NoAddressRegistered < StandardError; end

  param :username
  param :withdraw_address

  def call
    raise NoAddressRegistered if user.stellar_account.nil?
    raise NoTrustlineError unless merge_destination_account.trustline_exists?

    merge_account_tx.to_envelope.to_xdr(:base64)
  end

  private

  def merge_destination_account
    @merge_destination_account ||= Mobius::Client::Blockchain::Account.new(
      Mobius::Client.to_keypair(withdraw_address)
    )
  end

  def user
    @user ||= TipBot::User.new(username)
  end

  def merge_account_operations
    [transfer_assets_op, change_trust_op, merge_op]
  end

  def transfer_assets_op
    Stellar::Operation.payment(
      destination: merge_destination_account.keypair,
      amount: StellarHelpers.to_payment_amount(user.stellar_account.balance)
    )
  end

  def change_trust_op
    Stellar::Operation.change_trust(
      line: [
        :alphanum4,
        Mobius::Client.stellar_asset.code,
        Mobius::Client.to_keypair(Mobius::Client.stellar_asset.issuer)
      ],
      limit: 0
    )
  end

  def merge_op
    Stellar::Operation.account_merge(destination: merge_destination_account.keypair)
  end

  def merge_account_tx
    Stellar::Transaction
      .for_account(
        account: user.stellar_account.keypair,
        sequence: user.stellar_account.next_sequence_value,
        fee: 100 * merge_account_operations.size
      )
      .tap { |t| t.operations.concat(merge_account_operations) }
  end
end
