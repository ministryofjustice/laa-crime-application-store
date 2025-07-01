class AddSubscribersToApplications < ActiveRecord::Migration[8.0]
  def up
    add_column :application, :subscribers, :string, array: true

    Submission.all.each do |submission|
      submitter = %w[submitter provider].map { |key|
        email = submission.latest_version&.application&.dig(key, "email")
        email if email && email.match?(URI::MailTo::EMAIL_REGEXP)
      }.compact.first

      submission.subscribers ||= []
      submission.subscribers << submitter if submitter

      submission.save!
    end
  end

  def down
    remove_column :application, :subscribers
  end
end
