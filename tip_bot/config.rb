require "anyway"

class TipBot::Config < Anyway::Config
  env_prefix :mobius_tipbot

  attr_config(
    :redis_url,
    :token,
    :app_private_key,
    :credit_address,
    :smtp,
    :admin_email,
    :app_balance_alert_threshold,
    :chats_whitelist,
    :asset_code,
    :asset_issuer,
    network: :test,
    locale: :en,
    rate: 1.0,
  )
end
