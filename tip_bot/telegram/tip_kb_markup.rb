# Generates tip menu
class TipBot::Telegram::TipKbMarkup
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  param :people_count

  def call
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: tip_kb)
  end

  private

  def tip_kb
    @tip_kb ||= [
      button(
        text: TipBot.t(:button_text, count: people_count, scope: i18n_scope),
        callback_data: "tip"
      )
    ]
  end

  def button(*args)
    Telegram::Bot::Types::InlineKeyboardButton.new(*args)
  end

  def i18n_scope
    @i18n_scope ||= %i(telegram cmd tip).freeze
  end
end
