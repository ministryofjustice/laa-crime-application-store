class AlreadyExistsError < StandardError
  def initialize
    message = I18n.t("errors.submission.already_exists")

    super(message)
  end
end
