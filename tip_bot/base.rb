class TipBot::Base
  extend Dry::Initializer
  extend Forwardable

  def_delegator :TipBot, :logger

  param :token
  param :rate
  param :dapp

  class << self
    def start!(*args)
      new(*args).start!
    end
  end

  def start!
    raise ArgumentError, "Provide #{self.class.name} token!" if token.empty?
    logger.info t(:hello)
  end

  protected

  def client
    raise NotImplementedError, "Replace with bot client instance constructor"
  end

  def message(_message)
    raise NotImplementedError, "Replace with bot message parse command"
  end

  def i18n_scope
    @i18n_scope ||= self.class.name.split("::").last.downcase
  end

  def t(*args, **kwargs)
    I18n.t(*args, { scope: i18n_scope }.merge(kwargs))
  end
end
