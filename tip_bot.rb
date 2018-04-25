require "redis"
require "dry-initializer"
require "constructor_shortcut"
require "redis-namespace"
require "mobius/client"

module TipBot
  autoload :User,       "./tip_bot/user"
  autoload :TipMessage, "./tip_bot/tip_message"

  module Telegram
    module Command
      autoload :Balance,  "./tip_bot/telegram/command/balance"
      autoload :Base,     "./tip_bot/telegram/command/base"
      autoload :Start,    "./tip_bot/telegram/command/start"
      autoload :TipMenu,  "./tip_bot/telegram/command/tip_menu"
      autoload :Withdraw, "./tip_bot/telegram/command/withdraw"
    end

    autoload :Message,       "./tip_bot/telegram/message"
    autoload :TipKbMarkup,   "./tip_bot/telegram/tip_kb_markup"
    autoload :WebhookRouter, "./tip_bot/telegram/webhook_router"
  end

  class << self
    # Redis instance setter
    attr_writer :redis

    # Redis instance getter
    def redis
      @redis ||=
        ENV["MOBIUS_TIPBOT_REDIS_URL"] &&
        Redis::Namespace.new(:tipbot, redis: Redis.new(url: ENV["MOBIUS_TIPBOT_REDIS_URL"]))
    end

    # Logger instance setter
    attr_writer :logger

    # Logger instance getter
    def logger
      @logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
    end

    # Token setter
    attr_writer :token

    # Token getter
    def token
      @token ||= ENV["MOBIUS_TIPBOT_TOKEN"]
    end

    # Mobius::Client::App setter
    attr_writer :dapp

    # Mobius::Client::App getter
    def dapp
      @dapp ||= build_dapp
    end

    # Tip rate
    def tip_rate
      @tip_rate ||= (ENV["MOBIUS_TIPBOT_RATE"] || 1).to_f
    end

    # Sets up I18n, checks that required variables are present
    def configure!
      I18n.load_path = Dir.glob(File.join(File.dirname(__FILE__), "locales/*.yml"))
      I18n.locale = ENV["MOBIUS_TIPBOT_LOCALE"] || :en

      Mobius::Client.network = ENV["MOBIUS_TIPBOT_NETWORK"] == "public" ? :public : :test

      validate!
    end

    private

    def validate!
      i18n_args = { scope: :errors, locale: :en }

      raise ArgumentError, I18n.t(:token_missing, i18n_args) if token.nil?
      raise ArgumentError, I18n.t(:redis_missing, i18n_args) if redis.nil?
      raise ArgumentError, I18n.t(:dapp_missing, i18n_args) if dapp.nil?
    end

    def build_dapp
      app_creds = ENV.values_at("MOBIUS_TIPBOT_APP_PRIVATE_KEY", "MOBIUS_TIPBOT_CREDIT_ADDRESS")
      Mobius::Client::App.new(*app_creds) unless app_creds.any?(&:nil?)
    end
  end
end
