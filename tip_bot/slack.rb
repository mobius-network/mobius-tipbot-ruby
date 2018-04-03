require "slack-ruby-client"

class TipBot::Slack
  extend Dry::Initializer
  extend Forwardable

  def_delegator :TipBot, :logger

  param :token
  param :dapp

  class << self
    def start!(*args)
      new(*args).start!
    end
  end

  def start!
    logger.info "Starting Slack TipBot ..."

    client.on :hello, &method(:hello)
    client.on :message, &method(:message)

    client.start_async

    loop { Thread.pass }
  end

  private

  def hello(_data)
    logger.info "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team\
at https://#{client.team.domain}.slack.com."
  end

  def message(data)
    return if data.text.empty?
    text = data.text.split(" ")
    user = text.shift
    dispatch(text, data) if user == "<@#{client.self.id}>"
  end

  def dispatch(text, data)
    client.typing channel: data.channel
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

  def tip(text, data)
    nickname = text.shift.to_s[2..-2]
    user = client.users[nickname]

    return say(data, "Unknown user: <@#{nickname}>") if user.nil?

    tipbot_user = TipBot::User.new(nickname, dapp)
    tipbot_user.tip

    say(data, "<@#{nickname}>, you've been tipped!")
  rescue Mobius::Client::Error::InsufficientFunds
    say(data, "<@#{nickname}>, TipBot have not sufficient balance to send tips!")
  rescue Mobius::Client::Error
    say(data, "<@#{nickname}>, Error sending tip!")
  end

  def awaiting(data)
    user = TipBot::User.new(data.user, dapp)
    say(data, "Your balance awaiting for withdraw is #{user.balance}, use @tipbot withdraw <address> to get your tips!")
  end

  def withdraw(text, data)
    address = text.shift
    user = TipBot::User.new(data.user, dapp)
    user.withdraw(address)
    return say(data, "Provide target address to withdraw!") if address.nil? || address.empty?
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

  def app
    @app ||= TipBot::App.new(dapp)
  end
end
