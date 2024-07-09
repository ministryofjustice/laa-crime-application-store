require "rails_helper"

RSpec.describe "autogrant_events" do
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :autogrant_events
    end
  end

  let(:today) { Time.zone.now }
  let(:application_id) { SecureRandom.uuid }

  it "returns no records when no autogranted applications exist" do
    create(
      :submission,
      :with_pa_version,
      events: [{ id: 1, event_type: "new_version"}],
    )

    binding.pry

    expect(klass.all).to eq([])
  end

  it "when autogranted application exists with a translated service" do
    create(
      :submission,
      :with_pa_version,
      events: [{ id: 1, event_type: "auto_decision"}],
    )

    expect(klass.all).to eq([])
  end
end
