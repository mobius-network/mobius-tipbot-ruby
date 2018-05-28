# Job for notifying about low balance
class BalanceAlertJob
  include SuckerPunch::Job

  def perform(current_balance)
    return unless ENV["MOBIUS_TIPBOT_ADMIN_EMAIL"]

    Mail.deliver do
      from     "noreply@mobius-tipbot"
      to       ENV["MOBIUS_TIPBOT_ADMIN_EMAIL"]
      subject  "TipBot balance is low"
      body     "Balance went below threshold. Current balance is #{current_balance} #{TipBot.asset_code}"
    end
  end
end
