module ClaimTypeGroupHelper
  CLAIM_TYPE_MAP = {
    "NsmClaim" => %w[
      breach_of_injunction
      non_standard_magistrate
      non_standard_mag_supplemental
      non_standard_mag_appeal
      non_standard_mag_amendment
    ],
    "AssignedCounselClaim" => %w[
      assigned_counsel
      assigned_counsel_appeal
      assigned_counsel_amendment
    ],
  }.freeze

  def find_claim_type_group(request_type)
    CLAIM_TYPE_MAP.find { |_, types| types.include?(request_type) }&.first
  end
end
