class TipBot::TipButtonMessage
  extend Dry::Initializer
  extend Forwardable

  # @!method initialize
  # @param message [TipBot::TippedMessage] Telegram message object
  # @!scope instance
  param :tipped_message

  def_delegator :tipped_message, :count, :tips_count
  def_delegator :tipped_message, :button_message_id, :message_id
  def_delegators :tipped_message, :all_tippers, :balance, :author

  def heading_text
    all_tippers.size > 3 ? say_many_tippers : say_tippers
  end

  def button_layout
    TipBot::Telegram::TipKbMarkup.call(tips_count)
  end

  private

  def say_many_tippers
    TipBot.t(
      :heading_for_many_tippers,
      i18n_default_params.merge(more: all_tippers.size - 3)
    )
  end

  def say_tippers
    TipBot.t(:heading, i18n_default_params)
  end

  def i18n_default_params
    {
      usernames: tippers_display_string,
      amount: balance,
      recipient: author.display_name,
      recipient_total: author.balance,
      scope: i18n_scope
    }
  end

  def i18n_scope
    @i18n_scope ||= %i[telegram cmd tip].freeze
  end

  def tippers_display_string
    tippers_list = (all_tippers.size > 3 ? all_tippers.last(3) : all_tippers)
    tippers_list.map(&:display_name).join(", ")
  end
end
