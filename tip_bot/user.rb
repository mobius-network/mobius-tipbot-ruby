class TipBot::User
  extend Dry::Initializer

  param :nickname
  param :dapp, default: -> { TipBot.dapp }

  def tip(value)
    dapp.pay(value, target_address: address)
    increment(value) unless address
  end

  def address
    TipBot.redis.hget(REDIS_ADDRESS_KEY, nickname)
  end

  def balance
    TipBot.redis.hget(REDIS_BALANCE_KEY, nickname).to_f
  end

  def withdraw(address)
    dapp.transfer(balance, address)
    TipBot.redis.hset(REDIS_ADDRESS_KEY, nickname, address)
    TipBot.redis.hset(REDIS_BALANCE_KEY, nickname, 0)
  end

  private

  def increment(value)
    TipBot.redis.hincrbyfloat(REDIS_BALANCE_KEY, nickname, value)
  end

  REDIS_KEY = "mobius:tipbot".freeze
  REDIS_ADDRESS_KEY = "#{REDIS_KEY}:address".freeze
  REDIS_BALANCE_KEY = "#{REDIS_KEY}:balance".freeze
end
