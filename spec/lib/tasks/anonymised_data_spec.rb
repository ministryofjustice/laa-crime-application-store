require "rails_helper"

RSpec.describe "anonymised:" do
  let(:arbitrary_fixed_date) { Date.new(2024, 11, 1) }
  let(:anonymised_nsm_payload) do
    {
      application_risk: "low",
      application_type: "crm7",
      updated_at: "2024-11-01T00:00:00.000Z",
      created_at: "2024-11-01T00:00:00.000Z",
      last_updated_at: "2024-11-01T00:00:00.000Z",
      assigned_user_id: nil,
      application_state: "submitted",
      version: 1,
      json_schema_version: 1,
      application: {
        ufn: "010124/001",
        calls: 220,
        status: "submitted",
        letters: 500,
        solicitor: {
          last_name: "ANONYMISED",
          first_name: "ANONYMISED",
          previous_id: nil,
          contact_email: "ANONYMISED",
          reference_number: "1234567",
          contact_last_name: "ANONYMISED",
          contact_first_name: "ANONYMISED",
        },
        claim_type: "non_standard_magistrate",
        created_at: "2024-10-31T23:50:00.000Z",
        defendants: [
          {
            maat: "1234567",
            main: true,
            last_name: "ANONYMISED",
            first_name: "ANONYMISED",
          },
        ],
        updated_at: "2024-11-01T00:00:00.000Z",
        work_items: [
          {
            uplift: 0,
            position: 1,
            work_type: "preparation",
            fee_earner: "ANONYMISED",
            time_spent: 200,
            completed_on: "2024-01-01",
          },
        ],
        firm_office: {
          name: nil,
          town: "Lawyer Town",
          postcode: "CR0 1RE",
          previous_id: nil,
          account_number: "1A123B",
          address_line_1: "2 Laywer Suite",
          address_line_2: nil,
          vat_registered: "yes",
        },
        matter_type: "1",
        office_code: "1A123B",
        youth_court: true,
        calls_uplift: 20,
        disbursements: [
          {
            miles: 120.45,
            details: "Drive to court",
            position: 1,
            vat_rate: 0.2,
            apply_vat: true,
            other_type: nil,
            disbursement_date: "2025-01-01T00:00:00.000Z",
            disbursement_type: "motorcycle",
            total_cost_without_vat: 350.33,
          },
        ],
        laa_reference: "LAA-123456",
        letters_uplift: 10,
        rep_order_date: "2025-01-01T00:00:00.000Z",
        hearing_outcome: "CP01",
        work_completed_date: "2025-01-01T00:00:00.000Z",
      },
      events: [],
      application_id: submission_id,
    }
  end
  let(:anonymised_pa_payload) do
    {
      application_risk: "low",
      application_type: "crm4",
      updated_at: "2024-11-01T00:00:00.000Z",
      created_at: "2024-11-01T00:00:00.000Z",
      last_updated_at: "2024-11-01T00:00:00.000Z",
      assigned_user_id: nil,
      application_state: "submitted",
      version: 1,
      json_schema_version: 1,
      application: {
        ufn: "010124/001",
        quotes: [
          {
            period: 180,
            primary: true,
            postcode: "CRO 1RE",
            cost_type: "per_hour",
            travel_time: 150,
            organisation: "LAA",
            cost_per_hour: 10,
            contact_last_name: "ANONYMISED",
            contact_first_name: "ANONYMISED",
            travel_cost_reason: "a reason",
            travel_cost_per_hour: 50.0,
            related_to_post_mortem: true,
          },
        ],
        status: "submitted",
        defendant: {
          last_name: "ANONYMISED",
          first_name: "ANONYMISED",
        },
        solicitor: {
          previous_id: nil,
          contact_email: "ANONYMISED",
          reference_number: "1234567",
          contact_last_name: "ANONYMISED",
          contact_first_name: "ANONYMISED",
        },
        court_type: "other",
        created_at: "2024-10-31T23:50:00.000Z",
        updated_at: "2024-11-01T00:00:00.000Z",
        firm_office: {
          name: nil,
          town: "Lawyer Town",
          postcode: "CR0 1RE",
          previous_id: nil,
          account_number: "1A123B",
          address_line_1: "2 Laywer Suite",
          address_line_2: nil,
          vat_registered: "yes",
        },
        office_code: "1A123B",
        service_type: "ae_consultant",
        laa_reference: "LAA-123456",
        additional_costs: [
          {
            name: "stuff",
            items: 2,
            unit_type: "per_item",
            description: "some extra stuff",
            cost_per_item: 10.0,
          },
        ],
      },
      events: [],
      application_id: submission_id,
    }
  end
  let(:download_output) { "JSONSTART\n#{output_payload.to_json}\nJSONEND\n" }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    travel_to arbitrary_fixed_date
  end

  describe "download" do
    subject(:download) { Rake::Task["anonymised:download"].execute(arguments) }

    let(:arguments) { { laa_reference: } }
    let(:laa_reference) { "LAA-123456" }
    let(:submission_id) { submission.id }

    before do
      submission
      allow($stdout).to receive(:puts)
    end

    after { Rake::Task["anonymised:download"].reenable }

    context "when the submission is PA" do
      let(:submission) { create :submission, :with_pa_version, laa_reference: }
      let(:output_payload) { anonymised_pa_payload }

      it "downloads an anonymised version of the record" do
        expect { download }.to output(download_output).to_stdout
      end
    end

    context "when the submission is CRM7" do
      let(:submission) { create :submission, :with_nsm_version, laa_reference: }
      let(:output_payload) { anonymised_nsm_payload }

      it "downloads an anonymised version of the record" do
        expect { download }.to output(download_output).to_stdout
      end
    end
  end

  describe "import" do
    subject(:import) { Rake::Task["anonymised:import"].execute(arguments) }

    let(:arguments) { { env_var: } }
    let(:env_var) { "DATA" }
    let(:submission_id) { SecureRandom.uuid }

    before do
      allow(ENV).to receive(:[]).with(env_var).and_return(download_output)
    end

    after { Rake::Task["anonymised:download"].reenable }

    context "when the submission is PA" do
      let(:output_payload) { anonymised_pa_payload }

      it "creates a local record" do
        import
        imported = Submission.find(submission_id)
        expect(imported.application_type).to eq "crm4"
        expect(imported.latest_version.application).to eq anonymised_pa_payload[:application].deep_stringify_keys
      end
    end

    context "when the submission is NSM" do
      let(:output_payload) { anonymised_nsm_payload }

      it "creates a local record" do
        import
        imported = Submission.find(submission_id)
        expect(imported.application_type).to eq "crm7"
        expect(imported.latest_version.application).to eq anonymised_nsm_payload[:application].deep_stringify_keys
      end
    end
  end

  describe "delete" do
    subject(:delete) { Rake::Task["anonymised:delete"].execute(arguments) }

    let(:arguments) { { laa_reference: } }
    let(:laa_reference) { "LAA-123456" }
    let(:submission) { create :submission, :with_pa_version, laa_reference: }

    before do
      submission
    end

    it "deletes the submission" do
      delete
      expect(Submission.find_by(id: submission.id)).to be_nil
    end

    context "when in production" do
      before { allow(ENV).to receive(:[]).with("ENV").and_return("production") }

      it "raises and error" do
        expect { delete }.to raise_error "Cannot delete in a production environment"
      end
    end
  end
end
