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

  def dispatch(text, data)
    typing(data)
    command = text.shift

    case command
    when "awaiting" then awaiting(data)
    when "tip" then tip(text, data)
    when "withdraw" then withdraw(text, data)
    else
      unknown(command, data)
    end
  end

  def unknown(command, data)
    say(data, "Unknown command: #{command}")
  end

  # rubocop:disable Metrics/AbcSize
  def tip(text, data)
    nickname = text.shift.to_s[2..-2]
    user = client.users[nickname]

    return say(data, "Unknown user: <@#{nickname}>") if user.nil?

    TipBot::User.new(nickname, dapp).tip(tip_value)

    say(data, "<@#{nickname}>, you've been tipped!")
  rescue Mobius::Client::Error::InsufficientFunds
    say(data, "<@#{nickname}>, TipBot have not sufficient balance to send tips!")
  rescue Mobius::Client::Error
    say(data, "<@#{nickname}>, Error sending tip!")
  end
  # rubocop:enable Metrics/AbcSize

  def awaiting(data)
    user = TipBot::User.new(data.user, dapp)
    say(data, "Your balance awaiting for withdraw is #{user.balance}, use @tipbot withdraw <address> to get your tips!")
  end

  def withdraw(text, data)
    address = text.shift
    TipBot::User.new(data.user, dapp).withdraw(address)
    return say(data, "Provide target address to withdraw!") if address.nil?
    say(data, "Your tips has been successfully withdrawn to #{address}!")
  rescue Mobius::Client::Error::UnknownKeyPairType
    say(data, "Invalid target address: #{address}")
  end

  def client
    @client ||= Slack::RealTime::Client.new(token: token)
  end

  def say(data, text)
    client.message(channel: data.channel, text: text)
  end

  def typing(message)
    client.typing channel: message.channel
  end
end
