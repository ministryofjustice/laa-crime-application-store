module LaaReferenceHelper
  def generate_laa_reference
    ActiveRecord::Base.transaction do
      PaymentRequestClaim.lock
      loop do
        random_reference = "LAA-#{SecureRandom.alphanumeric(6)}"
        break random_reference unless reference_already_exists?(random_reference)
      end
    end
  end

  def reference_already_exists?(laa_reference)
    return true if find_referred_claim(laa_reference).present? || find_referred_submission(laa_reference)

    false
  end

  def find_referred_claim(laa_reference)
    PaymentRequestClaim.find_by(laa_reference:)
  end

  def find_referred_submission(laa_reference)
    SubmissionVersion.find_by("application->>'laa_reference' = ?", laa_reference)&.submission
  end
end
