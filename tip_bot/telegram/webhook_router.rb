require "rack"
require "multi_json"

# Rack router for Telegram webhooks
class TipBot::Telegram::WebhookRouter
  def call(env)
    request = Rack::Request.new(env)

    return noop unless request.post?

    body = MultiJson.load request.body.read
    token = request.path[1..-1]
    webhook(token, body)
  end

  private

  def noop
    [200, {}, []]
  end

  def webhook(token, data)
    if token == TipBot.config.token
      bot = Telegram::Bot::Client.new(TipBot.config.token)
      update = Telegram::Bot::Types::Update.new(data)

      TipBot::Telegram::Request.call(bot, update.message || update.callback_query)

      [200, {}, []]
    else
      TipBot.logger.error "WARNING. unexpected/unknown token: #{token}"
      [400, {}, []]
    end
  end
end
