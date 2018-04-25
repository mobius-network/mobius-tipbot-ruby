class TipBot::Telegram::TipKbMarkup
  extend ConstructorShortcut[:call]

  def call
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: tip_kb)
  end

  private

  def tip_kb
    @tip_kb ||= [
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: t(:tip, :tip, count: tip_message.count), callback_data: "tip"
      ),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: t(:tip, :skip), callback_data: "skip")
    ]
  end
end
