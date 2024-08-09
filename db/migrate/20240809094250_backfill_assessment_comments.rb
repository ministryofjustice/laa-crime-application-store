class BackfillAssessmentComments < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Submission.where(application_state: %w[granted rejected part_grant]).find_each do |submission|
      event = submission.events.detect { _1['event_type'] == 'decision' }
      next unless event

      version = submission.latest_version
      version.application['assessment_comment'] = event.dig('details', 'comment')
      version.save!(touch: false)
    end

    Submission.where(application_state: 'sent_back', application_type: 'crm7').find_each do |submission|
      event = submission.events.detect { _1['event_type'] == 'send_back' }
      next unless event

      version = submission.latest_version
      version.application['assessment_comment'] = event.dig('details', 'comment')
      version.save!(touch: false)
    end
  end
end
