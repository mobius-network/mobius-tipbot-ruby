if ENV["MOBIUS_TIPBOT_ENVIRONMENT"] == "development"
  require "pry-byebug"
  require "dotenv/load"
end

require "redis"
require "dry-initializer"
require "constructor_shortcut"
require "redis-namespace"
require "mobius/client"
require "tram-policy"
require "mail"
require "sucker_punch"

autoload :ApplicationPolicy, "./tip_bot/telegram/policy/application_policy"
autoload :WithdrawCommandValidnessPolicy, "./tip_bot/telegram/policy/withdraw_command_validness_policy"
autoload :CreateCommandValidnessPolicy, "./tip_bot/telegram/policy/create_command_validness_policy"
autoload :TipCommandValidnessPolicy, "./tip_bot/telegram/policy/tip_command_validness_policy"
autoload :StellarHelpers, "./tip_bot/utils/stellar_helpers"

autoload :BalanceAlertJob, "./tip_bot/jobs/balance_alert_job"

module TipBot
  autoload :Config,        "./tip_bot/config"
  autoload :User,          "./tip_bot/user"
  autoload :TippedMessage, "./tip_bot/tipped_message"
  autoload :TipButtonMessage, "./tip_bot/tip_button_message"

  module Telegram
    module Command
      autoload :Balance,  "./tip_bot/telegram/command/balance"
      autoload :Base,     "./tip_bot/telegram/command/base"
      autoload :Start,    "./tip_bot/telegram/command/start"
      autoload :Tip,      "./tip_bot/telegram/command/tip"
      autoload :TipCustomAmount, "./tip_bot/telegram/command/tip_custom_amount"
      autoload :TipMenu,  "./tip_bot/telegram/command/tip_menu"
      autoload :MyAddress, "./tip_bot/telegram/command/my_address"
      autoload :Create, "./tip_bot/telegram/command/create"
      autoload :CreateAck, "./tip_bot/telegram/command/create_ack"
      autoload :Unregister, "./tip_bot/telegram/command/unregister"
      autoload :UnregisterAck, "./tip_bot/telegram/command/unregister_ack"
      autoload :Withdraw, "./tip_bot/telegram/command/withdraw"
    end

    module Service
      autoload :TipMessage, "./tip_bot/telegram/service/tip_message"
      autoload :CreateAddress, "./tip_bot/telegram/service/create_address"
      autoload :UnregisterAddress, "./tip_bot/telegram/service/unregister_address"
      autoload :Withdraw, "./tip_bot/telegram/service/withdraw"
    end

    autoload :Request,       "./tip_bot/telegram/request"
    autoload :TipKbMarkup,   "./tip_bot/telegram/tip_kb_markup"
    autoload :WebhookRouter, "./tip_bot/telegram/webhook_router"
  end

  class << self
    # Redis instance setter
    attr_writer :redis

    def config
      @config ||= TipBot::Config.new
    end

    # Redis instance getter
    def redis
      @redis ||=
        config.redis_url &&
        Redis::Namespace.new(:tipbot, redis: Redis.new(url: config.redis_url))
    end

    # Logger instance setter
    attr_writer :logger

    # Logger instance getter
    def logger
      @logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
    end

    # Mobius::Client::App setter
    attr_writer :dapp

    # Mobius::Client::App getter
    def dapp
      @dapp ||= build_dapp
    end

    # It's actually some kind of hack to be able to
    # transfer money from dapp account itself
    def dev_dapp
      @dev_dapp ||= Mobius::Client::App.new(
        dapp.seed,
        Mobius::Client::Blockchain::KeyPairFactory.produce(dapp.seed).address
      )
    end

    def asset_code
      Mobius::Client.stellar_asset.code
    end

    def check_balance
      return unless config.app_balance_alert_threshold

      current_balance = dapp.balance

      return if current_balance > config.app_balance_alert_threshold

      BalanceAlertJob.perform_async(:low, current_balance)
    end

    def app_account
      @app_account ||= Mobius::Client::Blockchain::Account.new(app_keypair)
    end

    def app_keypair
      @app_keypair ||= Mobius::Client.to_keypair(dapp.seed)
    end

    # Sets up I18n and mobius client, then checks that required variables are present
    def configure!
      configure_i18n
      configure_mobius_client
      configure_mailer
      SuckerPunch.logger = logger
      validate!
    end

    def development?
      ENV["MOBIUS_TIPBOT_ENVIRONMENT"] == "development"
    end

    def t(key, **params)
      I18n.t(
        key,
        params.merge(tip_rate: config.rate, asset: Mobius::Client.asset_code)
      )
    end

    private

    def validate!
      i18n_args = { scope: :errors, locale: :en }

      raise ArgumentError, t(:token_missing, i18n_args) if TipBot.config.token.nil?
      raise ArgumentError, t(:redis_missing, i18n_args) if redis.nil?
      raise ArgumentError, t(:dapp_missing, i18n_args) if dapp.nil?
    end

    def configure_i18n
      I18n.load_path = Dir.glob(File.join(File.dirname(__FILE__), "locales/*.yml"))
      I18n.locale = config.locale || :en
    end

    def configure_mobius_client
      Mobius::Client.network = config.network
      asset_settings = [config.asset_code, config.asset_issuer]

      if asset_settings.any? && !asset_settings.all?
        return logger.warn(<<~MSG)
          You should provide both code and issuer, if you want to use custom Stellar asset for tips. Falling back to defaults (MOBI)
        MSG
      end

      Mobius::Client.asset_code = asset_settings[0]
      Mobius::Client.asset_issuer = asset_settings[1]
    end

    def configure_mailer
      return unless config.smtp["host"]

      Mail.defaults do
        delivery_method(
          :smtp,
          address: TipBot.config.smtp["host"],
          port: TipBot.config.smtp["port"],
          user_name: TipBot.config.smtp["username"],
          password: TipBot.config.smtp["password"]
        )
      end
    end

    def build_dapp
      app_creds = [config.app_private_key, config.credit_address]
      Mobius::Client::App.new(*app_creds) if app_creds.all?
    end
  end
end
