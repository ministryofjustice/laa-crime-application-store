require "rails_helper"

RSpec.describe "Assignments" do
  let(:submission) { create(:submission) }
  let(:caseworker_id) { SecureRandom.uuid }

  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

  describe "#create" do
    it "records the assignment" do
      post "/v1/submissions/#{submission.id}/assignment", params: { caseworker_id: }
      expect(response).to have_http_status :created

      expect(submission.reload.assigned_user_id).to eq caseworker_id
    end
  end

  describe "#destroy" do
    before { submission.update(assigned_user_id: caseworker_id, unassigned_user_ids: %w[foo]) }

    it "removes the assignment" do
      delete "/v1/submissions/#{submission.id}/assignment"
      expect(response).to have_http_status :no_content

      expect(submission.reload.assigned_user_id).to be_nil
    end

    it "adds to the previous assignee list" do
      delete "/v1/submissions/#{submission.id}/assignment"
      expect(response).to have_http_status :no_content

      expect(submission.reload.unassigned_user_ids).to eq ["foo", caseworker_id]
    end
  end
end
