# Policy for validating /withdraw command arguments
class WithdrawCommandValidnessPolicy < Tram::Policy
  root_scope "telegram", "policies"
  param :command

  option :destination_address, default: -> { command.address }
  option :user_balance, default: -> { command.user.balance }
  option :amount_to_withdraw, default: -> { command.amount }

  validate :balance_is_positive, stop_on_failure: true
  validate :destination_presence, stop_on_failure: true
  validate :valid_amount, stop_on_failure: true
  validate :amount_is_positive, stop_on_failure: true
  validate :sufficient_balance

  private

  def destination_presence
    return unless destination_address.nil?
    errors.add :address_missing
  end

  def balance_is_positive
    return if user_balance.positive?
    errors.add :balance_is_zero
  end

  def sufficient_balance
    return if amount_to_withdraw.nil? || user_balance >= amount_to_withdraw.to_f
    errors.add :insufficient_balance
  end

  def valid_amount
    return if amount_to_withdraw.nil? || Float(amount_to_withdraw) rescue false
    errors.add :invalid_amount
  end

  def amount_is_positive
    return if amount_to_withdraw.nil? || amount_to_withdraw.to_f.positive?
    errors.add :amount_is_not_positive
  end
end
