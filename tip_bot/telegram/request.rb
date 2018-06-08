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
    process_callback_query if subject.is_a?(Telegram::Bot::Types::CallbackQuery)
    dispatch if subject.is_a?(Telegram::Bot::Types::Message)
  end

  private

  def dispatch
    case message.text
    when "/start", "/help" then command("Start")
    when "/balance" then command("Balance")
    when %r(^\/tip) then command("TipMenu")
    when "/my_address" then command("MyAddress")
    when %r(^\/create) then command("Create")
    when %r(^\/unregister) then command("Unregister")
    when %r(^\/withdraw) then command("Withdraw")
    end
  end

  def command(klass)
    return say_chat_not_permitted unless chat_is_permitted?
    "TipBot::Telegram::Command::#{klass}".constantize.call(bot, message, subject)
  end

  def process_callback_query
    case subject.data
    when "tip" then TipBot::Telegram::Command::Tip.call(bot, message, subject)
    when %r(^reg_ack)
      TipBot::Telegram::Command::CreateAck.call(bot, message, subject)
    when "unreg_ack"
      TipBot::Telegram::Command::UnregisterAck.call(bot, message, subject)
    end
  end

  def chat_is_permitted?
    return true if TipBot.development? ||
                   TipBot.chats_whitelist.nil? ||
                   message.chat.type == "private"

    TipBot.chats_whitelist.include?(message.chat.id)
  end

  def say_chat_not_permitted
    bot.api.send_message(
      chat_id: message.chat.id,
      text: I18n.t(:chat_is_not_permitted, scope: :telegram)
    )
  end
end
