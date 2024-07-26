require "rails_helper"

RSpec.describe "processing times" do
  let(:base_time) { Time.new(2024, 6, 26, 12) }
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :processing_times
    end
  end

  it "will record draft to submitted when only one version" do
    submission = travel_to(base_time) { create(:submission, :with_pa_version) }

    expect(klass.all.map(&:attributes)).to eq([
      { "application_type" => "crm4",
        "from_date"=>Date.new(2024, 6, 26),
        "from_status"=>"draft",
        "from_time"=>Time.new(2024, 6, 26, 11, 50),
        "id"=>submission.id,
        "processing_seconds"=>600.0,
        "to_date"=>Date.new(2024, 6, 26),
        "to_status"=>"submitted",
        "to_time"=>Time.new(2024, 6, 26, 12),
        "version"=>1}
    ])
  end

  it "will record time between versions" do
    submission = travel_to(base_time) { create(:submission, :with_pa_version) }
    travel_to(base_time + 20.minutes) { create(:submission_version, :with_pa_application, submission:, status: 'approved', version: 2) }

    expect(klass.count).to eq(2)

    expect(klass.all.map(&:attributes)).to include(
      { "application_type" => "crm4",
        "from_date"=>Date.new(2024, 6, 26),
        "from_status"=>"submitted",
        "from_time"=>Time.new(2024, 6, 26, 12),
        "id"=>submission.id,
        "processing_seconds"=>1200.0,
        "to_date"=>Date.new(2024, 6, 26),
        "to_status"=>"approved",
        "to_time"=>Time.new(2024, 6, 26, 12, 20),
        "version"=>2}
    )
  end
end