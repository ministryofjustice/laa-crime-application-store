module LaaReferenceHelper
  CLAIM_CLASSES = [NsmClaim, AssignedCounselClaim].freeze
  def generate_laa_reference
    ActiveRecord::Base.transaction do
      CLAIM_CLASSES.each(&:lock)
      loop do
        random_reference = "LAA-#{SecureRandom.alphanumeric(6)}"
        break random_reference unless reference_already_exists?(random_reference)
      end
    end
  end

  def reference_already_exists?(laa_reference)
    return true if CLAIM_CLASSES.any? { _1.exists?(laa_reference: laa_reference) } || find_referred_submission(laa_reference)

    false
  end

  def find_referred_claim(laa_reference)
    CLAIM_CLASSES.map { _1.find_by(laa_reference:) }
      .find(&:present?)
  end

  def find_referred_submission(laa_reference)
    SubmissionVersion.find_by("application->>'laa_reference' = ?", laa_reference)&.submission
  end
end
