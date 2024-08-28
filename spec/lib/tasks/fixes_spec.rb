require "rails_helper"

describe "fixes:", type: :task do
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?

    allow($stdout).to receive(:write) # silence output from rake tasks
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
end
