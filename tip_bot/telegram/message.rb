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
    return unless message.is_a?(Telegram::Bot::Types::Message)

    case text
    when "/start" then start
    when "/balance" then balance
    when "/tip" then show_tip
    when %r(^\/withdraw) then withdraw
    end
  end

  private

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
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: tip_kb)
    bot.api.send_message(
      chat_id: chat.id,
      text: "@#{from.username} highly appreciates this message:",
      reply_to_message_id: message.message_id,
      reply_markup: markup
    )
  end

  # We can not tip bots, man himself and show standalone tipping menu.
  def tip_not_allowed?
    message.reply_to_message.nil? ||
      message.reply_to_message.from.id == from.id ||
      false#from.is_bot
  end

  def tip_kb
    @tip_kb ||= AMOUNTS.map do |value|
      Telegram::Bot::Types::InlineKeyboardButton.new(text: t(:kb_value, value: value), callback_data: value)
    end
  end

  def notify_cheater
    bot.api.send_chat_action(chat_id: chat.id, action: "Test")
  end

  def tip
    return if message.reply_to_message.nil?
    # bot.api.edit_message_text(message_id: message.message_id, text: "GIVE MORE TIPS", chat_id: chat.id)
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
