module DataMigrationTools
  class DisbursementPositionUpdater
    def initialize(submission_verion)
      @submission_version = submission_verion
    end

    def call
      disbursements ||= @submission_version.application["disbursements"]
      return unless disbursements

      disbursements.each_with_index do |disbursement, idx|
        position = disbursement_position(disbursement)

        @submission_version.application["disbursements"][idx]["position"] = position
        @submission_version.save!(touch: false)
      end
    end

  private

    def disbursements
      @submission_version.application["disbursements"]
    end

    def disbursement_position(disbursement)
      sorted_disbursement_ids.index(disbursement["id"]) + 1
    end

    def sorted_disbursement_ids
      @sorted_disbursement_ids = disbursements.sort_by { |disb|
        [
          disb["disbursement_date"].to_date || 100.years.ago,
          translated_disbursement_type(disb)&.downcase || "",
        ]
      }.pluck("id")
    end

    def translated_disbursement_type(disbursement)
      if disbursement["disbursement_type"]["value"] == "other"
        disbursement["other_type"]["en"]
      else
        disbursement["disbursement_type"]["en"]
      end
    end
  end
end
