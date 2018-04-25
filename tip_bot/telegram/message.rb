# Telegram message processor
# TODO: Refator #t, split to shorter classes
class TipBot::Telegram::Message
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
    callback if subject.is_a?(Telegram::Bot::Types::CallbackQuery)
    return unless subject.is_a?(Telegram::Bot::Types::Message)
    dispatch
  end

  private

  def dispatch
    case message.text
    when "/start" then command("Start")
    when "/balance" then command("Balance")
    when "/tip" then command("TipMenu")
    when %r(^\/withdraw) then command("Withdraw")
    end
  end

  def command(klass)
    "TipBot::Telegram::Command::#{klass}".constantize.call(bot, message, subject)
  end

  def show_tip
    return if tip_not_allowed?
    bot.api.send_message(
      chat_id: chat.id,
      text: tip_heading,
      reply_to_message_id: message_id,
      reply_markup: tip_kb_markup
    )
  end

  # We can not tip bots, man himself and show standalone tipping menu.
  def tip_not_allowed?
    message.reply_to_message.nil? ||
      message.reply_to_message.from.id == from.id ||
      false # from.is_bot DEBUG
  end

  def callback
    return can_not_tip_twice if tip_message.tipped?(from.username)

    user.tip
    tip_message.tip(from.username)

    update_tip_menu
  rescue Mobius::Client::Error::InsufficientFunds
    error_insufficient_funds
  rescue Mobius::Client::Error => e
    error_mobius_client(e)
  end

  def can_not_tip_twice
    bot.api.answer_callback_query(callback_query_id: subject.id, text: t(:cmd, :tip, :can_not_tip_twice))
  end

  def update_tip_menu
    bot.api.edit_message_text(
      message_id: message_id,
      chat_id: chat.id,
      text: tip_heading,
      reply_markup: tip_kb_markup
    )
  end

  def error_insufficient_funds
    bot.api.answer_callback_query(
      callback_query_id: subject.id, text: t(:cmd, :tip, :insufficient_funds)
    )
  end

  def error_mobius_client(err)
    bot.logger.error err.message
    bot.api.answer_callback_query(
      callback_query_id: subject.id, text: t(:cmd, :tip, :error)
    )
  end

  def tip_heading
    t(:tip, :heading, username: message.reply_to_message.from.username, amount: tip_message.balance)
  end

  def t(*path, **options)
    I18n.t(path.join("."), options.merge(scope: :telegram))
  end

  def direct_message?
    from.id == chat.id
  end

  def tip_message
    @tip_message ||= TipBot::TipMessage.new(message_id)
  end
end
# rubocop:enable Metrics/ClassLength
