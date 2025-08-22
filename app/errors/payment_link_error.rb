class PaymentLinkError < StandardError
  def initialize(message = nil)
    message = I18n.t("errors.payment_requests.invalid_link") if message.nil?

    super
  end
end
