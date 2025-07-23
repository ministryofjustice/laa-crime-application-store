module GenerateLaaReference
  CLAIM_CLASSES = [NsmClaim, AssignedCounselClaim].freeze
  def generate_laa_reference
    ActiveRecord::Base.transaction do
      CLAIM_CLASSES.each(&:lock)
      loop do
        random_reference = "LAA-#{SecureRandom.alphanumeric(6)}"
        break random_reference unless CLAIM_CLASSES.any? { _1.exists?(laa_reference: random_reference) } || SubmissionVersion.find_by("application->>'laa_reference' = ?", random_reference)
      end
    end
  end
end
