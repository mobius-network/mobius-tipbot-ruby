# Telegram message processor
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
    return unless message.is_a?(Telegram::Bot::Types::Message)

    case message.text
    when "/start" then start
    when "/balance" then balance
    when "/tip" then show_tip
    when %r(^\/withdraw) then withdraw
    end

    # return balance if message.text == "/balance"
    # return withdraw if message.text =~ %r(^\/withdraw)
    # return start if message.text == "/start"
    # show_tip if message.text == "/tip"
  end

  private

  def balance
    return unless direct_message?
    bot.api.send_message(chat_id: message.from.id, text: balance_reply)
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

  def show_tip
    return if tip_not_allowed?

    kb = [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '5', callback_data: '5'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '10', callback_data: '10'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '15', callback_data: '15')
    ]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)

    bot.api.send_message(
      chat_id: message.chat.id,
      text: "@#{message.from.username} highly appreciates this message:",
      reply_to_message_id: message.message_id,
      reply_markup: markup
    )
  end

  # We can not tip bots, man himself and show standalone tipping menu.
  def tip_not_allowed?
    message.reply_to_message.nil? ||
      message.reply_to_message.from.id == message.from.id ||
      message.from.is_bot
  end

  def notify_cheater
    bot.api.send_chat_action(chat_id: message.chat.id, action: "Test")
  end

  def tip
    return if message.reply_to_message.nil?
    # bot.api.edit_message_text(message_id: message.message_id, text: "GIVE MORE TIPS", chat_id: message.chat.id)
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
