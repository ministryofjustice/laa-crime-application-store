require "rails_helper"

RSpec.describe "adjust:fix_expired" do
  before do
    load "spec/lib/tasks/adjust_fix_provider_updated_data.rb"
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

    klass.where(Arel.sql("from_time > to_time"))

    expect(klass.where(Arel.sql("from_time > to_time")).pluck(:id, :from_time, :to_time)).to eq(
      [
        ["00061702-ce7b-4dc8-bc6c-ec13cf0ceae2", Time.parse("2024-06-25T12:51:32.494Z"), Time.parse("2024-06-24T16:15:46.909Z")],
      ],
    )

    Rake::Task["adjust:fix_provider_updated"].invoke

    # NOTE: 122976 seconds = 14 days
    expect(klass.where(Arel.sql("from_time > to_time")).pluck(:id)).to be_empty
  end
end
