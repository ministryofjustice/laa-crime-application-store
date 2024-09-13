require "rails_helper"

describe "fixes:", type: :task do
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  describe "update_contact_email" do
    subject(:run) do
      Rake::Task["fixes:update_contact_email"].execute(arguments)
    end

    let(:arguments) { Rake::TaskArguments.new %i[id new_contact_email], [submission.id, "correct@email.address"] }
    let(:solicitor) { { "contact_email" => "wrong@email.address" } }

    before do
      allow($stdin).to receive_message_chain(:gets, :strip).and_return("y")
    end

    context "with a submission" do
      let(:submission) { create(:submission, :with_nsm_version, solicitor:) }

      it "amends contact email" do
        subver = submission.latest_version

        expect { run }.to change { subver.reload.application["solicitor"]["contact_email"] }
          .from("wrong@email.address")
          .to("correct@email.address")
      end
    end

    context "with a prior authority application submission" do
      let(:submission) { create(:submission, :with_pa_version, solicitor:) }

      it "amends contact email" do
        subver = submission.latest_version

        expect { run }.to change { subver.reload.application["solicitor"]["contact_email"] }
          .from("wrong@email.address")
          .to("correct@email.address")
      end
    end

    context "when submission not found" do
      let(:arguments) { Rake::TaskArguments.new %i[id new_contact_email], ["non-existent-uuid", "correct@email.address"] }

      it "raises not found error" do
        expect { run }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "fix_corrupt_versions" do
    let(:affected_submission) { create(:submission, :with_pa_version, id: "dec31825-1bd1-461e-8857-5ddf9f839992", current_version: 3) }
    let(:unaffected_submission) { create(:submission, :with_pa_version, current_version: 3) }
    let(:deleted_version_id) { SecureRandom.uuid }

    before do
      affected_submission
      create(:submission_version, id: deleted_version_id, version: 2, submission: affected_submission)
      create(:submission_version, version: 3, submission: affected_submission)
      unaffected_submission
      create(:submission_version, version: 2, submission: unaffected_submission)
      create(:submission_version, version: 3, submission: unaffected_submission)
      Rails.application.load_tasks if Rake::Task.tasks.empty?
    end

    after do
      Rake::Task["fixes:fix_corrupt_versions"].reenable
    end

    it "removes correct submission version" do
      Rake::Task["fixes:fix_corrupt_versions"].execute
      expect(SubmissionVersion.find_by(id: deleted_version_id)).to be_nil
      expect(SubmissionVersion.find_by(application_id: unaffected_submission.id, version: 2)).to be_a SubmissionVersion
    end

    it "decrements the correct submission versions" do
      Rake::Task["fixes:fix_corrupt_versions"].execute
      expect(SubmissionVersion.find_by(application_id: affected_submission.id, version: 1)).to be_a SubmissionVersion
      expect(SubmissionVersion.find_by(application_id: affected_submission.id, version: 2)).to be_a SubmissionVersion
      expect(SubmissionVersion.find_by(application_id: affected_submission.id, version: 3)).to be_nil

      expect(SubmissionVersion.find_by(application_id: unaffected_submission.id, version: 1)).to be_a SubmissionVersion
      expect(SubmissionVersion.find_by(application_id: unaffected_submission.id, version: 2)).to be_a SubmissionVersion
      expect(SubmissionVersion.find_by(application_id: unaffected_submission.id, version: 3)).to be_a SubmissionVersion
    end

    it "resets submission current_version" do
      Rake::Task["fixes:fix_corrupt_versions"].execute
      expect(Submission.find(affected_submission.id).current_version).to eq(2)
      expect(Submission.find(unaffected_submission.id).current_version).to eq(3)
    end
  end

  describe "fix_corrupt_events" do
    # NOTE: only testing the first example to prove that the re-usable method #update_event_submission_version works
    let(:event_to_fix_id) { "d3003451-39f5-48c3-ba9f-f210491dad9b" }
    let(:unchanged_event_id) { SecureRandom.uuid }
    let(:events) do
      [
        {
          "id" => event_to_fix_id,
          "submission_version" => 1,
        },
        {
          "id" => unchanged_event_id,
          "submission_version" => 1,
        },
      ]
    end
    let(:submission) { create(:submission, :with_pa_version, id: "dec31825-1bd1-461e-8857-5ddf9f839992", events:) }

    before do
      submission
    end

    after do
      Rake::Task["fixes:fix_corrupt_versions"].reenable
    end

    it "fixes the correct event" do
      Rake::Task["fixes:fix_corrupt_events"].execute
      changed_event_version = Submission.first.events.find { |event| event["id"] == event_to_fix_id }
      unchanged_event_version = Submission.first.events.find { |event| event["id"] == unchanged_event_id }
      expect(changed_event_version["submission_version"]).to eq(2)
      expect(unchanged_event_version["submission_version"]).to eq(1)
    end
  end
end
