RSpec.shared_examples "notification client error handler" do
  # rubocop:disable RSpec/VerifiedDoubles
  context "when client error response received" do
    before do
      allow(Notifications::Client).to receive(:new)
        .and_return(notify_client)
      allow(notify_client).to receive(:send_email)
        .and_raise(Notifications::Client::BadRequestError.new(response))

      allow(Rails.logger).to receive(:warn)
    end

    let(:notify_client) { double("Notifications::Client") }

    context "when on DEV or UAT environment" do
      before do
        allow(HostEnv).to receive(:production?).and_return(false)
      end

      context "with a team API key client error" do
        let(:response) { double(code: 400, body: "Can't send to this recipient using a team-only API key") }

        it "does not raise error" do
          expect { described_class.notify(submission).deliver_now }.not_to raise_error
        end

        it "logs the rescued error" do
          described_class.notify(submission).deliver_now

          expect(Rails.logger)
            .to have_received(:warn)
            .with(/Swallowing exception Notifications::Client::BadRequestError with/)
        end
      end

      context "with another kind of client error" do
        let(:response) { double(code: 400, body: "some other client error") }

        it "raises error" do
          expect { described_class.notify(submission).deliver_now }
            .to raise_error(Notifications::Client::BadRequestError, "some other client error")
        end

        it "logs the rescued error" do
          described_class.notify(submission).deliver_now
        rescue Notifications::Client::BadRequestError
          expect(Rails.logger)
            .to have_received(:warn)
            .with(/Reraising exception Notifications::Client::BadRequestError with/)
        end
      end
    end

    context "when on production environment" do
      before do
        allow(HostEnv).to receive(:production?).and_return(true)
      end

      let(:response) { double(code: 400, body: "Can't send to this recipient using a team-only API key") }

      it "raises error" do
        expect { described_class.notify(submission).deliver_now }
          .to raise_error(Notifications::Client::BadRequestError, "Can't send to this recipient using a team-only API key")
      end

      it "logs the rescued error" do
        described_class.notify(submission).deliver_now
      rescue Notifications::Client::BadRequestError
        expect(Rails.logger)
          .to have_received(:warn)
          .with(/Reraising exception Notifications::Client::BadRequestError with/)
      end
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles
end
