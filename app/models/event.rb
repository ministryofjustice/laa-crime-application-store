class Event
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :primary_user_id, :string
  attribute :submission_version, :integer
  attribute :event_type, :string
  attribute :secondary_user_id, :string
  attribute :linked_type, :string
  attribute :linked_id, :string
  attribute :details
  attribute :created_at, :datetime, default: -> { Time.current }
  attribute :public, :boolean, default: false

  def as_json(*)
    super["attributes"]
  end
end
