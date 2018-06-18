# Tip storage
class TipBot::User
  extend Forwardable

  attr_reader :telegram_user

  # @param telegram_user [Telegram::Bot::Types::User, Hash] telegram user
  def initialize(object)
    if object.is_a?(Telegram::Bot::Types::User)
      @telegram_user = object
    elsif object.is_a?(Hash)
      @telegram_user = Telegram::Bot::Types::User.new(object)
    else
      raise ArgumentError "object must be Telegram::Bot::Types::User or Hash, #{object.class} given"
    end
  end

  def_delegators :telegram_user, :id, :username, :first_name, :last_name

  # Address linked to user
  # @return [String] Stellar address
  def address
    value = TipBot.redis.hget(REDIS_ADDRESS_KEY, id)
    value&.empty? ? nil : value
  end

  def address=(address)
    if address.nil?
      TipBot.redis.hdel(REDIS_ADDRESS_KEY, id)
    else
      TipBot.redis.hset(REDIS_ADDRESS_KEY, id, address)
    end
    @stellar_account = nil
  end

  # User balance
  # @return [Float] User balance
  def balance
    @balance ||= if stellar_account.nil?
                   redis_balance
                 else
                   stellar_account.balance.to_f
                 end
  end

  def reload_balance
    @balance = nil
    balance
  end

  def redis_balance
    TipBot.redis.hget(REDIS_BALANCE_KEY, id).to_f
  end

  def merge_balances
    return if stellar_account.nil? || redis_balance.zero?

    TipBot.dapp.charge(redis_balance, target_address: stellar_account.keypair.address)
    TipBot.redis.hdel(REDIS_BALANCE_KEY, id)
  end

  # Blocks user from sending tips for period
  def lock
    return if TipBot.development?
    TipBot.redis.set(redis_lock_key, true, nx: true, ex: LOCK_DURATION)
  end

  # Returns true if user is not allowed to send tips.
  # Users with registered custom Stellar accounts are never locked
  # @return [Boolean] true if locked
  def locked?
    (TipBot.redis.get(redis_lock_key) && true) || false
  end

  def increment_balance(value)
    TipBot.redis.hincrbyfloat(REDIS_BALANCE_KEY, id, value)
  end

  def decrement_balance(value)
    increment_balance(-value)
  end

  def stellar_account
    @stellar_account ||=
      address && Mobius::Client::Blockchain::Account.new(Mobius::Client.to_keypair(address))
  end

  def transfer_from_balance(amount, target_user)
    TipBot.redis.multi do
      decrement_balance(amount)
      target_user.increment_balance(amount)
    end
  end

  def transfer_money(amount, destination_address)
    Mobius::Client::App.new(TipBot.dapp.seed, address)
      .transfer(amount, destination_address)
  end

  def has_funded_address?
    address && balance.positive?
  end

  def display_name
    if username
      "@#{username}"
    else
      "#{first_name} #{last_name}".strip
    end
  end

  private

  def redis_lock_key
    "#{REDIS_LOCK_KEY}:#{id}".freeze
  end

  REDIS_ADDRESS_KEY = "address".freeze
  REDIS_BALANCE_KEY = "balance".freeze
  REDIS_LOCK_KEY = "lock".freeze
  LOCK_DURATION = 3600
end
