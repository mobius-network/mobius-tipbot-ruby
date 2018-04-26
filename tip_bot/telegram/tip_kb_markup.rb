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
      button(text: I18n.t(:tip, count: people_count, scope: i18n_scope), callback_data: "tip"),
      button(text: I18n.t(:skip, scope: i18n_scope), callback_data: "skip")
    ]
  end

  def button(*args)
    Telegram::Bot::Types::InlineKeyboardButton.new(*args)
  end

  def i18n_scope
    @i18n_scope ||= %i(telegram tip).freeze
  end
end
