require "telegram/bot"

class TipBot::Telegram < TipBot::Base
  def start!
    client.run { |client| client.listen { |message| message(message) } }
  end

  private

  def message(message)
    return if message.text.empty?
    text = message.text.split(" ")
    dispatch(text, message)
  end

  def dispatch(text, message)
    command = text.shift
    # # case message.text
    # # when '/start'
    # #   bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}")
    # # when '/stop'
    # #   bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
    # # end
    #
    case command
    when "/awaiting" then awaiting_cmd(message, message.from.username)
    when "/tip" then tip(text, message)
    # when "withdraw" then withdraw(text, data)
    else
      unknown(command, message)
    end
  end

  def tip(text, message)
    nickname = text.shift.to_s[1..-1]
    m = message.entities[1]
    tip_cmd(message, nickname, m && m.type == "mention")
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
    @client ||= Telegram::Bot::Client.new(token, logger: logger)
  end

  def say(base_message, text)
    client.api.send_message(chat_id: base_message.chat.id, text: text)
  end

  def app
    @app ||= TipBot::App.new(dapp)
  end

  def tip_value
    (rate || 1).to_f
  end
end
