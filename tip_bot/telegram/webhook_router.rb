require "rack"
require "multi_json"

# Rack router for Telegram webhooks. NOTE: Untested yet.
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
    TipBot.logger.debug(data)
    if token == TipBot.token
      bot = Telegram::Bot::Client.new(TipBot.token)
      update = Telegram::Bot::Types::Update.new(data)
      message = update.message

      TipBot::Telegram::Request.call(bot, message)

      [200, {}, []]
    else
      TipBot.logger.error "WARNING. unexpected/unknown token: #{token}"
      [400, {}, []]
    end
  end
end
