class TipBot::User
  extend Dry::Initializer

  param :nickname
  param :dapp

  def tip
    dapp.pay(TIP_AMOUNT, target_address: address)
    increment unless address
  end

  def address
    TipBot.redis.hget("#{REDIS_KEY}:address", nickname)
  end

  def balance
    TipBot.redis.hget("#{REDIS_KEY}:balance", nickname).to_f
  end

  def withdraw(address)
    dapp.transfer(TIP_AMOUNT, address)
    TipBot.redis.hset("#{REDIS_KEY}:address", nickname, address)
    TipBot.redis.hset("#{REDIS_KEY}:balance", nickname, 0)
  end

  private

  def increment
    TipBot.redis.hincrby("#{REDIS_KEY}:balance", nickname, TIP_AMOUNT)
  end

  REDIS_KEY = "mobius:tipbot".freeze
  TIP_AMOUNT = 1
end
