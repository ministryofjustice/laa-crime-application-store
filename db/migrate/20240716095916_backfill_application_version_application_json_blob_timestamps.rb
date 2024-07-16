class BackfillApplicationVersionApplicationJsonBlobTimestamps < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Update CRM4 application blobs to have the timestamps if they do not
    #
    # It has been agreed to update these timestamps to be the created_at for
    # the application record itself because, in ~95% of cases this will be
    # within seconds of the actual timestamp of submission from provider.
    #
    # We set the json's updated_at to reflect this "almost submission" timestamp
    # We set the json's created_at to the same, despite this being inaccurate, as it
    #  - makes it easier to identify in the future if necessary
    #  - would be onerous to extract actual created_at dates from provider app and serve
    #    little purpose.
    #
    # Note that these timestamps are now being set on submission from provider, going forward,
    # in any event, so we only need to update those where they are null.
    #
    SubmissionVersion
      .joins(:submission)
      .where(submission: { application_type: 'crm4' })
      .where("application->>'created_at' IS NULL AND application->>'updated_at' IS NULL")
      .each do |ver|
        ver.application['created_at'] = ver.submission.created_at
        ver.application['updated_at'] = ver.submission.created_at
        ver.save(touch: false)

        sleep(0.001)  # throttle
    end
  end
end
