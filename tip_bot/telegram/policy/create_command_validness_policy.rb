# Policy for validating /create command arguments
class CreateCommandValidnessPolicy < Tram::Policy
  root_scope "telegram", "policies"
  param :command

  option :source_address, default: -> { command.address }
  option :deposit_amount, default: -> { command.deposit_amount }

  validate :source_address_presence, stop_on_failure: true
  validate :amount_presence, stop_on_failure: true
  validate :valid_amount, stop_on_failure: true
  validate :amount_is_positive, stop_on_failure: true

  private

  def amount_presence
    return if deposit_amount
    errors.add :deposit_amount_missing
  end

  def valid_amount
    return if Float(deposit_amount) rescue false
    errors.add :invalid_deposit_amount
  end

  def amount_is_positive
    return if deposit_amount.to_f.positive?
    errors.add :deposit_amount_is_not_positive
  end

  def source_address_presence
    return if source_address
    errors.add :source_address_missing
  end
end
