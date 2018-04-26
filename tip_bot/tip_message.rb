# Saves stats for tipped message
class TipBot::TipMessage
  extend Dry::Initializer

  # @!method initialize
  # @param message_id [Integer] Telegram message id
  # @!scope instance
  param :message_id

  # Returns overall tips sum in currency for the message
  # @return [Float] tips sum
  def balance
    TipBot.redis.get(redis_balance_key).to_f
  end

  # Tips the message
  # @param nickname [String] tipper's nickname
  # @param value [Numeric] tip's value
  # @return [Integer] 1 if tip was successful
  def tip(nickname, value = TipBot.tip_rate)
    TipBot.redis.incrbyfloat(redis_balance_key, value)
    TipBot.redis.sadd(redis_lock_key, nickname)
  end

  # Returns true if user with given nickname tipped the message already
  # @param nickname [String] user's nickname
  # @return [Boolean]
  def tipped?(nickname)
    TipBot.redis.sismember(redis_lock_key, nickname)
  end

  # Returns overall tips count for the message
  # @return [Integer] tips count
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

  BASE_KEY = "message".freeze
  REDIS_BALANCE_KEY = "#{BASE_KEY}:balance".freeze
  REDIS_LOCK_KEY = "#{BASE_KEY}:lock".freeze
end
