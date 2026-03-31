require "rails_helper"

RSpec.describe "autogrant_events" do
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :autogrant_events
    end
  end

  let(:today) { Time.zone.now }

  before do
    Translation.find_or_create_by(key: "ae_consultant", translation: "A&E consultant", translation_type: "service")
  end

  it "returns no records when no autogranted applications exist" do
    create(
      :submission,
      :with_pa_version,
      state: :granted,
    )

    expect(klass.all).to eq([])
  end

  it "when autogranted application exists with a translated service" do
    submission = create(
      :submission,
      :with_pa_version,
      state: :auto_grant,
    )

    expect(klass.all.map(&:attributes)).to eq([
      { "id" => submission.id, "submission_version" => 1, "event_on" => today.to_date, "service_key" => "ae_consultant", "service" => "A&E consultant" },
    ])
  end

  it "when autogranted application exists with a custom service" do
    submission = create(
      :submission,
      :with_custom_pa_version,
      state: :auto_grant,
    )

    expect(klass.all.map(&:attributes)).to eq([
      { "id" => submission.id, "submission_version" => 1, "event_on" => today.to_date, "service_key" => "custom", "service" => "Test" },
    ])
  end
end
