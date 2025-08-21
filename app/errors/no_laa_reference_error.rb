class NoLaaReferenceError < StandardError
  def initialize
    message = I18n.t("errors.submission.no_laa_ref")

    super(message)
  end
end
