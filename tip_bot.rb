require "redis"
require "dry-initializer"

module TipBot
  autoload :User,     "./tip_bot/user"
  autoload :Base,     "./tip_bot/base"
  autoload :Slack,    "./tip_bot/slack"
  autoload :Telegram, "./tip_bot/telegram"

  class << self
    attr_writer :redis
    def redis
      @redis ||= Redis.new
    end

    attr_writer :logger
    def logger
      @logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
    end

    def configure!
      I18n.load_path = Dir.glob(File.join(File.dirname(__FILE__), "locales/*.yml"))
      I18n.locale = ENV["MOBIUS_TIPBOT_LOCALE"] || :en

      %w(
        MOBIUS_TIPBOT_REDIS_URL
        MOBIUS_TIPBOT_APP_PRIVATE_KEY
        MOBIUS_TIPBOT_CREDIT_ADDRESS
      ).each do |var|
        raise ArgumentError, "Provide #{var} value!" if var.nil? || var.empty?
      end
    end
  end
end
