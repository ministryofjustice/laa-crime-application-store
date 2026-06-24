require "rails_helper"

RSpec.describe "autogrant_events" do
  let(:view_definition) { Rails.root.join("db/views/autogrant_events_v04.sql").read }
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :autogrant_events
    end
  end

  let(:today) { Time.zone.now }

  before do
    Translation.find_or_create_by(key: "ae_consultant", translation: "A&E consultant", translation_type: "service")
  end

  it "keeps the Metabase dashboard field names" do
    expect(klass.column_names).to eq(%w[id submission_version event_on service_key service])
  end

  it "filters to autogrants without using the legacy event views" do
    expect(view_definition).to match(/FROM\s+application\s+a/i)
    expect(view_definition).to include("a.state = 'auto_grant'")
    expect(view_definition).not_to include("application_type")
    expect(view_definition).not_to match(/\ball_events\b/i)
  end

  it "has a partial index supporting the autogrant application filter" do
    index = ActiveRecord::Base.connection.indexes(:application).find do |idx|
      idx.name == "idx_application_auto_grant_current_version"
    end

    expect(index).to be_present
    expect(index.columns).to eq(%w[id current_version])
    expect(index.where).to match(/state.*auto_grant/)
    expect(index.where).not_to match(/application_type/)
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

  it "keeps non-CRM4 autogranted applications in the output" do
    submission = create(
      :submission,
      :with_nsm_version,
      state: :auto_grant,
    )

    expect(klass.all.map(&:attributes)).to eq([
      { "id" => submission.id, "submission_version" => 1, "event_on" => today.to_date, "service_key" => nil, "service" => nil },
    ])
  end
end
