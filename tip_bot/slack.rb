require "slack-ruby-client"

class TipBot::Slack < TipBot::Base
  def start!
    super

    client.on :hello, &method(:hello)
    client.on :message, &method(:receive)

    client.start_async

    loop { Thread.pass }
  end

  private

  def hello(_data)
    logger.info t(
      :"cmd.hello",
      name: client.self.id,
      client_name: client.self.name,
      team_name: client.team.name,
      domain: client.team.domain
    )
  end

  def receive(message)
    return if message.text.empty?
    text = message.text.split(" ")
    user = text.shift
    dispatch(text, message) if mentioned?(user)
  end

  def mentioned?(user)
    user == "<@#{client.self.id}>"
  end

  def dispatch(text, message)
    typing(message)
    command = text.shift

    case command
    when "awaiting" then awaiting_cmd(message, message.user)
    when "tip" then tip(text, message)
    when "withdraw" then withdraw_cmd(text, message, message.user)
    else
      unknown(command, message)
    end
  end

  def tip(text, message)
    nickname = text.shift.to_s[2..-2]
    user = client.users[nickname]
    tip_cmd(message, nickname, !user.nil?)
  end

  def client
    @client ||= Slack::RealTime::Client.new(token: token)
  end

  def say(base_message, text)
    client.message(channel: base_message.channel, text: text)
  end

  def typing(message)
    client.typing channel: message.channel
  end
end
