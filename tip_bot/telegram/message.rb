# Telegram message processor
class TipBot::Telegram::Message
  extend Dry::Initializer
  extend ConstructorShortcut[:call]
  extend Forwardable

  # @!method initialize(seed)
  # @param bot [Telegram::Bot] Bot instance
  # @param message [Telegram::Bot::Types::Message] Message
  # @!scope instance
  param :bot
  param :message

  def_delegators :@message, :from, :chat, :text

  def call
    callback if message.is_a?(Telegram::Bot::Types::CallbackQuery)
    return unless message.is_a?(Telegram::Bot::Types::Message)
    dispatch
  end

  private

  def dispatch
    case text
    when "/start" then start
    when "/balance" then balance
    when "/tip" then show_tip
    when %r(^\/withdraw) then withdraw
    end
  end

  def start
    type = chat.id == from.id ? :private : :public
    text = t(:cmd, :start, type, username: from.username)
    bot.api.send_message(chat_id: from.id, text: text, parse_mode: "Markdown")
  end

  def balance
    return unless direct_message?
    bot.api.send_message(chat_id: from.id, text: balance_reply)
  end

  def balance_reply
    return t(:cmd, :balance, :linked, address: user.address) if user.address
    t(:cmd, :balance, :value, balance: user.balance)
  end

  def withdraw
    return unless direct_message?
    address = text.split(" ").last
    bot.api.send_message(chat_id: from.id, text: withdraw_reply(address))
  end

  def withdraw_reply(address)
    return t(:cmd, :withdraw, :address_missing) if address.nil?
    return t(:cmd, :withdraw, :nothing) if user.balance.zero?
    user.withdraw(address)
    t(:cmd, :withdraw, :done, address: address)
  rescue Mobius::Client::Error::UnknownKeyPairType
    t(:cmd, :withdraw, :invalid_address, address: address)
  end

  def show_tip
    return if tip_not_allowed?
    bot.api.send_message(
      chat_id: chat.id,
      text: t(:tip_heading, username: from.username, amount: 0),
      reply_to_message_id: message.message_id,
      reply_markup: tip_kb_markup
    )
  end

  # We can not tip bots, man himself and show standalone tipping menu.
  def tip_not_allowed?
    message.reply_to_message.nil? ||
      message.reply_to_message.from.id == from.id ||
      false # from.is_bot DEBUG
  end

  def tip_kb
    @tip_kb ||= AMOUNTS.map do |value|
      Telegram::Bot::Types::InlineKeyboardButton.new(text: t(:kb_value, value: value), callback_data: value)
    end
  end

  def tip_kb_markup
    @tip_kb_markup ||= Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: tip_kb)
  end

  def callback
    # Little weird, message.message, but it's because message is ::CallbackQuery
    m = message.message
    text = t(:tip_heading, username: m.from.username, amount: message.data)

    bot.api.edit_message_text(
      message_id: m.message_id,
      chat_id: m.chat.id,
      text: text,
      reply_markup: tip_kb_markup
    )
  end

  def t(*path, **options)
    I18n.t(path.join("."), options.merge(scope: :telegram))
  end

  def direct_message?
    from.id == chat.id
  end

  def user
    @user ||= TipBot::User.new(from.username)
  end

  AMOUNTS = [5, 10, 100, 1000].freeze
end
