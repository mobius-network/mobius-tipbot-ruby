class TipBot::Telegram::Message
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  # @!method initialize(seed)
  # @param bot [Telegram::Bot] Bot instance
  # @param message [Telegram::Bot::Types::Message] Message
  # @!scope instance
  param :bot
  param :message

  def call
    # Telegram::Bot::Types::CallbackQuery
    # start
    return unless message.is_a?(Telegram::Bot::Types::Message)
    return balance if message.text == "/balance"
    return withdraw if message.text =~ %r(^\/withdraw)
    return tip if message.text == "/tip"
  end

  private

  def balance
    # return unless direct_message?
    bot.api.send_message(chat_id: message.from.id, text: balance_reply)
    bot.api.send_message(chat_id: message.chat.id, text: balance_reply)
  end

  def balance_reply
    return t(:cmd, :balance, :linked, address: user.address) if user.address
    t(:cmd, :balance, :value, balance: user.balance)
  end

  def withdraw
    return unless direct_message?
    address = message.text.split(" ").last
    bot.api.send_message(chat_id: message.from.id, text: withdraw_reply(address))
  end

  def withdraw_reply(address)
    return t(:cmd, :withdraw, :address_missing) if address.nil?
    return t(:cmd, :withdraw, :nothing) if user.balance.zero?
    user.withdraw(address)
    t(:cmd, :withdraw, :done, address: address)
  rescue Mobius::Client::Error::UnknownKeyPairType
    t(:cmd, :withdraw, :invalid_address, address: address)
  end

  def tip
    return if message.reply_to_message.nil?
    kb = [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '1', callback_data: '1'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '5', callback_data: '5'),
    ]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
    bot.api.send_message(
      chat_id: message.chat.id,
      text: "How much to tip?",
      reply_to_message_id: message.reply_to_message.message_id,
      reply_markup: markup
    )
  end

  def t(*path, **options)
    I18n.t(path.join("."), options.merge(scope: :telegram))
  end

  def direct_message?
    message.from.id == message.chat.id
  end

  def user
    @user ||= TipBot::User.new(message.from.username)
  end
end
