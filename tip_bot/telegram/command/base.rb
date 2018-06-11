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

  def user
    @user ||= TipBot::User.new(from)
  end

  def respond(text)
    api.send_message(chat_id: chat.id, text: text)
  end

  def reply(text)
    api.send_message(chat_id: chat.id, text: text, reply_to_message_id: message_id)
  end

  def answer_callback_query(text)
    api.answer_callback_query(callback_query_id: subject.id, text: text)
  end

  protected

  def t(key, **options)
    TipBot.t(key, { scope: command_scope }.merge(options))
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
end
