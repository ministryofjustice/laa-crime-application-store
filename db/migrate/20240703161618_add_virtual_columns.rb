class AddVirtualColumns < ActiveRecord::Migration[7.1]
  def change
    search_vector = <<~VECTOR
      TO_TSVECTOR('simple', COALESCE(application -> 'defendant' ->> 'first_name', '')) || \
      TO_TSVECTOR('simple', COALESCE(application -> 'defendant' ->> 'last_name', '')) || \
      TO_TSVECTOR('simple', jsonb_path_query_array(application,  '$.defendants[*].first_name')) || \
      TO_TSVECTOR('simple', jsonb_path_query_array(application, '$.defendants[*].last_name')) || \
      TO_TSVECTOR('simple', COALESCE(application -> 'firm_office' ->> 'name', ''))
    VECTOR

    add_column(
      :application_version,
      :search_fields,
      :virtual,
      as: search_vector,
      type: :tsvector,
      stored: true
    )
    # ufn and laa_reference had to be extracted from tsvector due to `/` and `-` characters
    # not being parsed as desired
    add_column(
      :application_version,
      :ufn,
      :virtual,
      as: "COALESCE(application ->> 'ufn', '')",
      type: :string,
      stored: true
    )
    add_column(
      :application_version,
      :laa_reference,
      :virtual,
      as: "COALESCE(application ->> 'laa_reference', '')",
      type: :string,
      stored: true
    )

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
