class TipBot::Message
  extend Dry::Initializer

  param :message_id

  def originator
  end

  def originator=(value)
  end

  def balance
  end

  def balance=
  end

  def tipped?(nickname)
  end

  def record(nickname)
  end
end
