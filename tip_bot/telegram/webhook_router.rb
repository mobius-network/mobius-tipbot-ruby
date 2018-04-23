require "rack"
require "multi_json"

class TipBot::Telegram::WebhookRouter
  def call(env)
    request = Rack::Request.new(env)

    return noop unless request.post?

    body = MultiJson.load request.body.read
    token = request.path[1..-1].to_sym
    webhook(token, body)
  end

  private

  def noop
    [200, {}, []]
  end

  def webhook(token, data)
    if token == TipBot.token
      bot = Telegram::Bot::Client.new(TipBot.token)
      update = Telegram::Bot::Types::Update.new(data)
      message = update.message

      TipBot::Telegram::Message.call(bot, message)

      [200, {}, []]
    else
      TipBot.logger.error "WARNING. unexpected/unknown token: #{token}"
      [400, {}, []]
    end
  end
end
