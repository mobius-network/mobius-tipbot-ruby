# Saves stats for tipped message
class TipBot::TippedMessage
  extend Dry::Initializer

  # @!method initialize
  # @param message [Telegram::Bot::Types::Message] Telegram message object
  # @!scope instance
  param :message

  # Returns overall tips sum in currency for the message
  # @return [Float] tips sum
  def balance
    TipBot.redis.get(key(:balance)).to_f
  end

  # Tips the message
  # @param nickname [String] tipper's nickname
  # @param value [Numeric] tip's value
  # @return [Integer] 1 if tip was successful
  def tip(nickname, value = TipBot.tip_rate)
    TipBot.redis.incrbyfloat(key(:balance), value || TipBot.tip_rate)
    TipBot.redis.zadd(key(:lock), count + 1, nickname)
  end

  # Returns true if user with given nickname tipped the message already
  # @param nickname [String] user's nickname
  # @return [Boolean]
  def tipped?(nickname)
    !TipBot.redis.zscore(key(:lock), nickname).nil?
  end

  # Returns overall tips count for the message
  # @return [Integer] tips count
  def count
    TipBot.redis.zcard(key(:lock)).to_i
  end

  def all_tippers
    TipBot.redis.zrange(key(:lock), 0, -1)
  end

  # Stores id of bot's message with tip button for future references
  # @param keyboard_message_id Telegram message id
  def attach_button(keyboard_message_id)
    TipBot.redis.set(key(:keyboard_message), keyboard_message_id)
  end

  # Returns id of bot's message with tip button
  # @ return [Integer] Telegram message id
  def button_message_id
    TipBot.redis.get(key(:keyboard_message))&.to_i
  end

  def author
    @author ||= TipBot::User.new(message.from)
  end

  private

  def key(scope)
    "#{BASE_KEY}:#{scope}:chat:#{message.chat.id}:#{message.message_id}".freeze
  end

  BASE_KEY = "message".freeze
end
