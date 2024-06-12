module Redactable
  extend ActiveSupport::Concern

  included do
    has_one :redacted_submission_version, dependent: :destroy, autosave: true
    before_save :perform_redacting
  end

  def perform_redacting
    Rails.logger.debug { "==> Redacting application ID blah" }
    Redacting::Redact.new(self).process!
  end
end
