# Job for notifying about low balance
class BalanceAlertJob
  include SuckerPunch::Job

  def perform(message, current_balance = nil)
    return unless TipBot.config.admin_email
    return unless %i[low exhausted].include?(message.to_sym)

    i18n_options = default_i18n_options.merge(current_balance: current_balance)

    Mail.deliver do
      from     "noreply@mobius-tipbot"
      to       TipBot.config.admin_email
      subject  TipBot.t("#{message}.subject", i18n_options)
      body     TipBot.t("#{message}.body", i18n_options)
    end
  end

  private

  def default_i18n_options
    {
      scope: %i[telegram jobs balance_alert],
      asset: TipBot.asset_code
    }
  end
end
