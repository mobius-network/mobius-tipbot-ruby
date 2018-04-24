class TipBot::TipMessage
  extend Dry::Initializer

  param :message_id

  def balance
    TipBot.redis.get(redis_balance_key).to_f
  end

  def tip(nickname, value = TipBot.tip_rate)
    TipBot.redis.incrbyfloat(redis_balance_key, value)
    TipBot.redis.sadd(redis_lock_key, nickname)
  end

  def tipped?(nickname)
    TipBot.redis.sismember(redis_lock_key, nickname)
  end

  def count
    TipBot.redis.scard(redis_lock_key).to_i
  end

  private

  def redis_balance_key
    "#{REDIS_BALANCE_KEY}:#{message_id}".freeze
  end

  def redis_lock_key
    "#{REDIS_LOCK_KEY}:#{message_id}".freeze
  end

  BASE_KEY = "#{TipBot::REDIS_KEY}:message".freeze
  REDIS_BALANCE_KEY = "#{BASE_KEY}:balance".freeze
  REDIS_LOCK_KEY = "#{BASE_KEY}:lock".freeze
end
