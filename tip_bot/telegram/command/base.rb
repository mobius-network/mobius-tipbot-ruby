# Base command handler
class TipBot::Telegram::Command::Base
  extend Dry::Initializer
  extend ConstructorShortcut[:call]
  extend Forwardable

  param :bot
  param :message
  param :subject

  def_delegators :message, :from, :chat, :text, :message_id, :reply_to_message
  def_delegator :from, :username
  def_delegator :bot, :api

  def call
    raise NotImplementedError, "Implement command response behaviour in child class"
  end

  protected

  def t(key, **options)
    I18n.t(key, { scope: command_scope }.merge(options))
  end

  def direct_message?
    from.id == chat.id
  end

  def empty_username?
    from.username.nil? || from.username == ""
  end

  def command_scope
    [:telegram, :cmd, self.class.name.split("::").last.downcase]
  end

  def user
    @user ||= TipBot::User.new(username)
  end
end
