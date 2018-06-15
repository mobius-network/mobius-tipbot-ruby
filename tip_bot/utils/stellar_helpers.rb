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
  end
end
