# Job for notifying about low balance
class BalanceAlertJob
  include SuckerPunch::Job

  def perform(message, current_balance = nil)
    return unless ENV["MOBIUS_TIPBOT_ADMIN_EMAIL"]
    return unless %i[low exhausted].include?(message.to_sym)

    i18n_options = default_i18n_options.merge(current_balance: current_balance)

    Mail.deliver do
      from     "noreply@mobius-tipbot"
      to       ENV["MOBIUS_TIPBOT_ADMIN_EMAIL"]
      subject  I18n.t("#{message}.subject", i18n_options)
      body     I18n.t("#{message}.body", i18n_options)
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
