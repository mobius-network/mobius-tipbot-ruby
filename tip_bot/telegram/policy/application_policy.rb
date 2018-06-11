class ApplicationPolicy < Tram::Policy
  root_scope "telegram", "policies"

  def t(message, **options)
    return message.to_s unless message.is_a? Symbol
    TipBot.t message, scope: scope, **options
  end
end
