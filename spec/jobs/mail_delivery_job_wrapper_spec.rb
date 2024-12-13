require "rails_helper"

# rubocop:disable Rails/ApplicationMailer, Rails/I18nLocaleTexts
RSpec.describe MailDeliveryJobWrapper do
  before do
    ActionMailer::Base.add_delivery_method :govuk_notify, GovukNotifyRails::Delivery,
                                           api_key: "fake-test-key"
  end

  it "ensures 'to' is always an array" do
    mailer_class = Class.new(ActionMailer::Base) do
      default delivery_method: :govuk_notify

      def test_email
        mail(
          to: "invalid@email.",
          subject: "Test",
          body: "Test content",
        )
      end
    end

    mail = mailer_class.test_email
    job = described_class.set(queue: :mailers).perform_later(
      mailer_class.name,
      "test_email",
      "deliver_now",
      mail.to,
      {},
    )

    serialized_job = job.serialize
    args = serialized_job["arguments"]
    expect(args[3]).to be_an(Array)
  end
end
# rubocop:enable Rails/ApplicationMailer, Rails/I18nLocaleTexts
