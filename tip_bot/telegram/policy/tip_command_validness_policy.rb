# Policy for validating /tip command invocation
class TipCommandValidnessPolicy < Tram::Policy
  root_scope "telegram", "policies"

  option :amount
  option :message_to_tip
  option :tipper

  validate :tipper_username_is_present, stop_on_failure: true
  validate :used_in_reply, stop_on_failure: true
  validate :not_tipping_self, stop_on_failure: true
  validate :not_tipped_already, stop_on_failure: true
  validate :not_tipping_bot, stop_on_failure: true
  validate :not_locked_tipper, stop_on_failure: true
  validate :valid_amount, stop_on_failure: true
  validate :balance_is_present_for_amount, stop_on_failure: true
  validate :balance_is_sufficient

  def tipper_username_is_present
    return unless tipper.username.nil? || tipper.username == ""
    errors.add(:tipper_username_missing)
  end

  def used_in_reply
    return unless message_to_tip.nil?
    errors.add(:not_in_reply)
  end

  def not_tipping_self
    return if message_to_tip.from.id != tipper.id
    errors.add(:tipping_self)
  end

  def not_tipped_already
    tipped_message = TipBot::TippedMessage.new(message_to_tip)
    return unless tipped_message.tipped?(tipper.username)
    errors.add(:already_tipped)
  end

  def not_tipping_bot
    return unless message_to_tip.from.is_bot
    errors.add(:tipping_bot)
  end

  def not_locked_tipper
    return unless tipper.locked?
    errors.add(:can_not_tip_often)
  end

  def valid_amount
    return if amount.nil? || (Float(amount).positive? rescue false)
    errors.add(:invalid_amount, amount: amount)
  end

  def balance_is_present_for_amount
    return if amount.nil? || tipper.balance.positive?
    errors.add(:can_not_tip_custom_amount)
  end

  def balance_is_sufficient
    return if amount.nil? || tipper.balance >= amount.to_f
    errors.add(:insufficient_balance)
  end
end
