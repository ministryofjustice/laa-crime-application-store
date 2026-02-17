require "rails_helper"

RSpec.describe PaymentRequests::CreatePaymentRequestService, type: :service do
  let(:submitter_id) { SecureRandom.uuid }
  let(:request_type) { "non_standard_magistrate" }
  let(:laa_reference) { nil }
  let(:idempotency_token) { SecureRandom.uuid }
  let(:params) do
    {
      submitter_id:,
      request_type:,
      laa_reference:,
      idempotency_token:,
      date_received: "2025-01-01",
      solicitor_office_code: "3B123A",
      solicitor_firm_name: "The Firm",
      defendant_first_name: "Jim",
      defendant_last_name: "Jones",
      matter_type: "CRIM",
      hearing_outcome_code: "PROG",
      stage_reached: "PROG",
      ufn: "010125/001",
      youth_court: false,
      number_of_attendances: 2,
      number_of_defendants: 1,
      date_completed: "2025-01-01",
      court: "Greenock Sheriff",
      claimed_profit_cost: 100.0,
      claimed_travel_cost: 20.0,
      claimed_waiting_cost: 10.0,
      claimed_disbursement_cost: 5.0,
      allowed_profit_cost: 90.0,
      allowed_travel_cost: 15.0,
      allowed_waiting_cost: 5.0,
      allowed_disbursement_cost: 4.0,
    }
  end

  let(:service) { described_class.new(params) }

  describe "#supplemental_appeal_or_ammendment?" do
    {
      "non_standard_mag_supplemental" => true,
      "assigned_counsel_amendment" => true,
      "non_standard_mag_appeal" => true,
      "non_standard_magistrate" => false,
    }.each do |request_type, expected|
      it "returns #{expected} when request_type is '#{request_type}'" do
        params = { request_type: request_type }
        result = described_class.new(params).send(:supplemental_appeal_or_ammendment?)
        expect(result).to eq(expected)
      end
    end
  end

  describe "#find_or_create_claim!" do
    context "when laa_reference is present and request_type has a supplemental/appeal/amendment suffix" do
      subject(:service) { described_class.new(params) }

      let(:params) { { idempotency_token: SecureRandom.uuid, laa_reference: "LAA123", request_type: "non_standard_mag_appeal" } }

      it "returns the existing claim if found" do
        existing = create(:payment_request_claim, laa_reference: "LAA123")
        expect(service.send(:find_or_create_claim!)).to eq(existing)
      end

      it "raises UnprocessableEntityError if no matching claim found" do
        expect {
          service.send(:find_or_create_claim!)
        }.to raise_error(described_class::UnprocessableEntityError, /Claim not found/)
      end
    end

    context "when inferring linking an existing submission claim from linked_laa_reference param" do
      let(:linked_laa_reference) { "LAA-EXISTING" }
      let(:service) { described_class.new(params) }

      describe "when linked_laa_reference exists" do
        let(:params) { super().except(:laa_reference).merge({ linked_laa_reference: linked_laa_reference }) }

        it "links the submission ref to the payment" do
          expect(service.call[:claim][:laa_reference]).to eq(linked_laa_reference)
        end
      end

      describe "when linked_laa_reference does not exist" do
        let(:params) { super().except(:laa_reference) }

        it "creates a new laa_reference for the payment" do
          expect(service.call[:claim][:laa_reference]).not_to eq(linked_laa_reference)
        end
      end
    end

    context "when creating a new claim" do
      let(:params) do
        { idempotency_token: SecureRandom.uuid,
          request_type: "non_standard_magistrate" }
      end

      it "creates an NsmClaim for NSM types" do
        allow(service).to receive_messages(claim_type: "NsmClaim", nsm_claim_details: { firm_name: "Firm X" })

        expect(NsmClaim).to receive(:create!).with(hash_including(firm_name: "Firm X"))
        service.send(:find_or_create_claim!)
      end

      it "creates an AssignedCounselClaim for assigned counsel types" do
        allow(service).to receive_messages(claim_type: "AssignedCounselClaim", assigned_counsel_claim_details: { solicitor_office_code: "S123" })

        expect(AssignedCounselClaim).to receive(:create!).with(hash_including(solicitor_office_code: "S123"))
        service.send(:find_or_create_claim!)
      end

      it "raises UnprocessableEntityError when claim_type is unknown" do
        allow(service).to receive(:claim_type).and_return(nil)
        expect {
          service.send(:find_or_create_claim!)
        }.to raise_error(described_class::UnprocessableEntityError, /Unknown claim type/)
      end
    end
  end

  describe "persisting linked submissions" do
    let(:linked_laa_reference) { "LAA-EXISTING" }

    context "when a submission exists for the linked reference" do
      let!(:submission) { create(:submission, :with_nsm_version, laa_reference: linked_laa_reference) }
      let(:params) { super().merge(linked_laa_reference:, id: submission.id) }

      it "stores the submission id on the claim" do
        result = service.call
        expect(result[:claim].reload.submission_id).to eq(submission.id)
      end
    end

    context "when no submission exists for the linked reference" do
      let(:params) { super().merge(linked_laa_reference:, id: SecureRandom.uuid) }

      it "leaves submission_id as nil" do
        result = service.call
        expect(result[:claim].reload.submission_id).to be_nil
      end
    end
  end

  describe "#assign_costs" do
    let(:payment_request) { build(:payment_request) }

    context "when assigns_cost by claim_type" do
      let(:params) do
        {
          idempotency_token: SecureRandom.uuid,
          request_type: "non_standard_magistrate",
          claimed_profit_costs: 100,
          allowed_disbursement_costs: 50,
        }
      end

      it "assigns NSM cost attributes" do
        expect(service).to receive(:claim_type)
        service.send(:assign_costs, payment_request)
      end
    end

    context "when claim_type is NsmClaim" do
      let(:params) do
        {
          idempotency_token: SecureRandom.uuid,
          request_type: "non_standard_magistrate",
          claimed_profit_cost: 100,
          allowed_disbursement_cost: 50,
        }
      end

      it "assigns NSM cost attributes" do
        allow(service).to receive(:claim_type).and_return("NsmClaim")
        service.send(:assign_costs, payment_request)
        expect(payment_request.claimed_profit_cost).to eq(100)
        expect(payment_request.allowed_disbursement_cost).to eq(50)
      end
    end

    context "when claim_type is AssignedCounselClaim" do
      let(:params) do
        {
          idempotency_token: SecureRandom.uuid,
          request_type: "assigned_counsel",
          claimed_net_assigned_counsel_cost: 200,
          claimed_assigned_counsel_vat: 40,
        }
      end

      it "assigns assigned counsel cost attributes" do
        allow(service).to receive(:claim_type).and_return("AssignedCounselClaim")
        service.send(:assign_costs, payment_request)
        expect(payment_request.claimed_net_assigned_counsel_cost).to eq(200)
        expect(payment_request.claimed_assigned_counsel_vat).to eq(40)
      end
    end
  end

  describe "#call" do
    let(:params) do
      {
        idempotency_token: SecureRandom.uuid,
        request_type: "non_standard_magistrate",
        submitter_id: SecureRandom.uuid,
        date_received: Time.zone.today,
      }
    end

    context "when everything succeeds" do
      it "returns the created claim" do
        claim = build_stubbed(:nsm_claim)
        payment_request = build_stubbed(:payment_request)
        allow(service).to receive_messages(find_or_create_claim!: claim, build_payment_request: payment_request)
        allow(service).to receive(:assign_costs)
        allow(payment_request).to receive(:save).and_return(true)

        expect(service.call).to eq({ claim:, payment_request: })
      end
    end

    context "when find_or_create_claim! returns nil" do
      it "raises UnprocessableEntityError" do
        allow(service).to receive(:find_or_create_claim!).and_return(nil)
        expect { service.call }.to raise_error(described_class::UnprocessableEntityError, /Unable to determine claim type/)
      end
    end

    context "when payment_request fails to save" do
      it "raises UnprocessableEntityError with validation message" do
        claim = build_stubbed(:nsm_claim)
        payment_request = build_stubbed(:payment_request)
        allow(service).to receive_messages(find_or_create_claim!: claim, build_payment_request: payment_request)
        allow(service).to receive(:assign_costs)
        allow(payment_request).to receive(:save).and_return(false)
        allow(payment_request).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return("Validation failed")

        expect { service.call }.to raise_error(described_class::UnprocessableEntityError, /Validation failed/)
      end
    end

    context "when claim creation raises ActiveRecord::RecordInvalid" do
      it "wraps the exception in UnprocessableEntityError" do
        allow(service).to receive(:find_or_create_claim!).and_raise(ActiveRecord::RecordInvalid.new(NsmClaim.new))
        expect { service.call }.to raise_error(described_class::UnprocessableEntityError)
      end
    end
  end
end
