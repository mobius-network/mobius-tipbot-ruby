# Telegram message processor
class TipBot::Telegram::Request
  extend Dry::Initializer
  extend ConstructorShortcut[:call]
  extend Forwardable

  # @!method initialize(seed)
  # @param bot [Telegram::Bot] Bot instance
  # @param subject [Telegram::Bot::Types::*] Subject
  # @!scope instance
  param :bot
  param :subject

  # Returns Telegram::Bot::Types::Message for whenever subject
  # @return [Telegram::Bot::Types::Message] Message object
  def message
    @message ||= subject.is_a?(Telegram::Bot::Types::CallbackQuery) ? subject.message : subject
  end

  # Parses message text and calls desired command
  def call
    tip_button_press if subject.is_a?(Telegram::Bot::Types::CallbackQuery)
    return unless subject.is_a?(Telegram::Bot::Types::Message)
    dispatch
  end

  private

  def dispatch
    case message.text
    when "/start" then command("Start")
    when "/balance" then command("Balance")
    when "/tip" then command("TipMenu")
    when "/my_address" then command("MyAddress")
    when %r(^\/register) then command("Register")
    when %r(^\/withdraw) then command("Withdraw")
    end
  end

  def command(klass)
    "TipBot::Telegram::Command::#{klass}".constantize.call(bot, message, subject)
  end

  def tip_button_press
    TipBot::Telegram::Command::Tip.call(bot, message, subject)
  end
end
