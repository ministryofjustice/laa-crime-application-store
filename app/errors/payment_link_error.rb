class PaymentLinkError < StandardError
  def initialize
    message = I18n.t("errors.payment_requests.invalid_link")

    super(message)
  end
end
