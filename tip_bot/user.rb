class TipBot::User
  extend Dry::Initializer

  param :nickname
  param :dapp

  def tip(value)
    dapp.pay(value, target_address: address)
    increment(value) unless address
  end

  def address
    TipBot.redis.hget("#{REDIS_KEY}:address", nickname)
  end

  def balance
    TipBot.redis.hget("#{REDIS_KEY}:balance", nickname).to_f
  end

  def withdraw(address)
    dapp.transfer(balance, address)
    TipBot.redis.hset("#{REDIS_KEY}:address", nickname, address)
    TipBot.redis.hset("#{REDIS_KEY}:balance", nickname, 0)
  end

  private

  def increment(value)
    TipBot.redis.hincrbyfloat("#{REDIS_KEY}:balance", nickname, value)
  end

  REDIS_KEY = "mobius:tipbot".freeze
end
