namespace :anonymised do
  desc "Print an anonymised version of the payload"
  task :download, [:laa_reference] => :environment do |_, args|
    submission = Submission.joins(:ordered_submission_versions)
                           .find_by("application_version.application->>'laa_reference' = ?",
                                    args[:laa_reference])
    service_type = submission.application_type == 'crm7' ? :nsm : :prior_authority
    anonymised = LaaCrimeFormsCommon::Anonymiser.anonymise(
      service_type,
      submission.latest_version.application
    )
    puts "JSONSTART"
    puts submission.as_json.merge(application: anonymised).to_json
    puts "JSONEND"
  end

  desc "Import a submission from a named env var"
  task :import, [:env_var] => :environment do |_, args|
    data = ENV[args[:env_var]]
    json = data.split("JSONSTART").last.split("JSONEND").first
    content = JSON.parse(json)
    Submission.transaction do
      submission = Submission.create!(
        content.slice(
          *%w[application_risk application_type updated_at created_at last_updated_at assigned_user_id events]
        ).merge(
          id: content["application_id"],
          state: content["application_state"],
          current_version: content["version"],
        )
      )

      submission.ordered_submission_versions.create!(
        json_schema_version: content["json_schema_version"],
        application: content["application"],
        version: content["version"],
      )
    end
  end

  desc "Delete a submission based on its LAA reference"
  task :delete, [:laa_reference] => :environment do |_, args|
    raise "Cannot delete in a production environment" if ENV["ENV"] == "production"

    submission = Submission.joins(:ordered_submission_versions)
                           .find_by("application_version.application->>'laa_reference' = ?",
                                    args[:laa_reference])
    submission.destroy!
  end
end
