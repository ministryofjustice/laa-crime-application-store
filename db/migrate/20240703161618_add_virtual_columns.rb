class AddVirtualColumns < ActiveRecord::Migration[7.1]
  def change
    # NOTE: we remove the '-' from laa_reference as otherwise the to_query will break it
    # NOTE: we use weight:
    # * A - ufn and laa-reference
    # * B - all other fields
    # this allow us to avoid partial matches on ufn and laa-reference to some extent
    search_vector = <<~VECTOR
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'defendant' ->> 'first_name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'defendant' ->> 'last_name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', jsonb_path_query_array(application,  '$.defendants[*].first_name')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', jsonb_path_query_array(application, '$.defendants[*].last_name')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'firm_office' ->> 'name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application ->> 'ufn', '')), 'A') || \
      SETWEIGHT(TO_TSVECTOR('simple', REPLACE(LOWER(COALESCE(application ->> 'laa_reference', '')), '-', '')), 'A')
    VECTOR

    add_column(
      :application_version,
      :search_fields,
      :virtual,
      as: search_vector,
      type: :tsvector,
      stored: true
    )
    add_index(:application_version, :search_fields, using: 'gin')

    # How the query works
    # '$[*] ? (@.event_type == \"assignment\").primary_user_id'
    # $[*]                               => search through each element of the array
    # ? (@.event_type == \"assignment\") => filter to rows that have an event type of 'assignment'
    # .primary_user_id                   => return the primary_user_id from the filtered rows
    add_column(
      :application,
      :has_been_assigned_to,
      :virtual,
      as: "jsonb_path_query_array(events, '$[*] ? (@.event_type == \"assignment\").primary_user_id')",
      type: :jsonb,
      stored: true
    )
  end
end
