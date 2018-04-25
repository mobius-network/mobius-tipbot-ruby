# Tip storage
class TipBot::User
  extend Dry::Initializer

  # @!method initialize(seed)
  # @param nickname [String] User nickname
  # @param dapp [Mobius::Client::App] Application instance
  # @!scope instance
  param :nickname
  param :dapp, default: -> { TipBot.dapp }

  # Tips user for given value
  # @param value [Float] Value in selected currency
  def tip(value = TipBot.tip_rate)
    dapp.pay(value, target_address: address)
    increment(value) unless address
  end

  # Address linked to user
  # @return [String] Stellar address
  def address
    TipBot.redis.hget(REDIS_ADDRESS_KEY, nickname)
  end

  # User balance
  # @return [Float] User balance
  def balance
    TipBot.redis.hget(REDIS_BALANCE_KEY, nickname).to_f
  end

  # Sends accumulated tips to given address, records address in database
  # @param address [String] Stellar address
  def withdraw(address)
    dapp.transfer(balance, address)
    TipBot.redis.hset(REDIS_ADDRESS_KEY, nickname, address)
    TipBot.redis.hset(REDIS_BALANCE_KEY, nickname, 0)
  end

  private

  def increment(value)
    TipBot.redis.hincrbyfloat(REDIS_BALANCE_KEY, nickname, value)
  end

  REDIS_ADDRESS_KEY = "address".freeze
  REDIS_BALANCE_KEY = "balance".freeze
end
