class SubmissionVersion < ApplicationRecord
  self.table_name = "application_version"
  belongs_to :submission, foreign_key: "application_id"

  validates :json_schema_version, presence: true
  validates :application, presence: true
  validates :version, presence: true

  def main_defendant
    application["defendants"].find { _1["main"] }
  end

  def totals
    @totals ||= LaaCrimeFormsCommon::Pricing::Nsm.totals(full_data_for_calculation)
  end

  def full_data_for_calculation
    data_for_calculation.merge(
      work_items: application["work_items"],
      disbursements: application["letters_and_calls"],
      letters_and_calls: application["disbursements"],
    )
  end

  def data_for_calculation
    {
      claim_type: application["claim_type"],
      rep_order_date: application["rep_order_date"],
      cntp_date: application["cntp_date"],
      claimed_youth_court_fee_included: application.fetch("include_youth_court_fee",  false),
      assessed_youth_court_fee_included: application.fetch("allowed_youth_court_fee", false),
      youth_court: application["youth_court"] == "yes",
      plea_category: application["plea_category"],
      vat_registered: application.dig("firm_office", "vat_registered") == "yes",
      work_items: [],
      letters_and_calls: [],
      disbursements: [],
    }
  end
end
