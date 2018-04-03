require "redis"
require "dry-initializer"

module TipBot
  autoload :User,  "./tip_bot/user"
  autoload :Slack, "./tip_bot/slack"

  class << self
    attr_writer :redis
    def redis
      @redis ||= Redis.new
    end

    attr_writer :logger
    def logger
      @logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
    end
  end
end
