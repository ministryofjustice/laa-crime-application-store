class AuthorizationService
  def self.call(subject, category, verb, params, object)
    return :no_op if Authorization::Rules::NO_OPS.dig(category.to_sym, verb.to_sym)&.call(object, params)

    rule = Authorization::Rules::PERMISSIONS.dig(subject, category.to_sym, verb.to_sym)

    permitted = if rule.respond_to?(:call)
                  rule.call(object, params)
                else
                  rule
                end

    permitted ? :allowed : :forbidden
  end
end
