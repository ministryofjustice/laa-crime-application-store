class AuthorizationService
  def self.call(subject, category, verb, params, object)
    rule = Authorization::Rules::PERMISSIONS.dig(subject, category.to_sym, verb.to_sym)

    if rule.respond_to?(:call)
      rule.call(object, params)
    else
      rule
    end
  end
end
