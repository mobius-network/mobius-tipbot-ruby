require "mobius/client"
require "redis"

class Storage
  class << self
    attr_accessor :redis

    attr_writer :redis_key
    def redis_key
      @redis_key ||= "mobius-tipbot"
    end
  end

  def total
    balance.sum { |_, v| v.to_f }
  end

  def tips
    self.class.redis.hgetall(self.class.redis_key)
  end
end
