# Various helpers for creating Stellar-specific objects
class StellarHelpers
  class << self
    def to_signer(account, weight: 1)
      Stellar::Signer.new(
        key: Stellar::SignerKey.new(
          :signer_key_type_ed25519,
          account.keypair.raw_public_key
        ),
        weight: weight
      )
    end

    def to_payment_amount(value)
      Stellar::Amount.new(value, Mobius::Client.stellar_asset).to_payment
    end

    def transfer(from:, to:, amount:)
      post_tx(payment_txe(from_account: from, to_address: to, amount: amount))
    end

    def post_tx(txe)
      Mobius::Client.horizon_client.horizon.transactions._post(tx: txe)
    end

    def payment_txe(from_account:, to_address:, amount:)
      Stellar::Transaction
        .payment(
          account: from_account.keypair,
          sequence: from_account.next_sequence_value,
          destination: Mobius::Client.to_keypair(to_address),
          amount: to_payment_amount(amount)
        )
        .to_envelope(TipBot.app_keypair)
        .to_xdr(:base64)
    end
  end
end
