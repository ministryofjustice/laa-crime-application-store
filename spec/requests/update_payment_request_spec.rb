require "rails_helper"

RSpec.describe "Update payment request" do
  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }
end
