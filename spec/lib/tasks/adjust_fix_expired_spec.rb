require "rails_helper"

RSpec.describe "adjust:fix_expired" do
  before do
    load "spec/lib/tasks/adjust_fix_expired_data.rb"
  end

  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :processing_times
    end
  end

  it "Processes as expected" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("PERSIST_ADJUSTMENT").and_return("true")
    Rails.application.load_tasks if Rake::Task.tasks.empty?

    expect(klass.where(to_status: "expired").pluck(:id, :processing_seconds)).to eq(
      [
        ["14994bfc-95c2-4ddb-94a0-1b84cbc1f7f0", 0.0],
        ["73c46945-0a6c-4b3a-a828-661de16edd79", 0.0],
        ["bd080793-01d5-4882-9b42-360f123ec8b7", 0.0],
        ["fcc2f94e-a2bd-422e-b59a-53210fa52bd5", 0.0],
      ],
    )

    Rake::Task["adjust:fix_expired"].invoke

    # NOTE: 122976 seconds = 14 days
    expect(klass.where(to_status: "expired").pluck(:id, :processing_seconds)).to eq(
      [
        ["14994bfc-95c2-4ddb-94a0-1b84cbc1f7f0", 1_249_625.179],
        ["73c46945-0a6c-4b3a-a828-661de16edd79", 1_243_270.139],
        ["bd080793-01d5-4882-9b42-360f123ec8b7", 1_235_002.357],
        ["fcc2f94e-a2bd-422e-b59a-53210fa52bd5", 1_244_228.889],
      ],
    )
  end
end
