class StupidForwardSlash < ActiveRecord::Migration[7.1]
  def up
    new_search_vector = <<~VECTOR
      SETWEIGHT(TO_TSVECTOR('simple', REPLACE(COALESCE(application -> 'defendant' ->> 'first_name', ''), '/', '-')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', REPLACE(COALESCE(application -> 'defendant' ->> 'last_name', ''), '/', '-')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', replace(jsonb_path_query_array(application,  '$.defendants[*].first_name')::text, '/', '-')::jsonb), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', replace(jsonb_path_query_array(application, '$.defendants[*].last_name')::text, '/', '-')::jsonb), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', REPLACE(COALESCE(application -> 'firm_office' ->> 'name', ''), '/', '-')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application ->> 'ufn', '')), 'A') || \
      SETWEIGHT(TO_TSVECTOR('simple', REPLACE(LOWER(COALESCE(application ->> 'laa_reference', '')), '-', '')), 'A')
    VECTOR

    drop_view :searches
    remove_column(:application_version, :search_fields)
    add_column(
      :application_version,
      :search_fields,
      :virtual,
      as: new_search_vector,
      type: :tsvector,
      stored: true
    )
    add_index(:application_version, :search_fields, using: 'gin')
    create_view :searches
  end

  def down
    old_search_vector = <<~VECTOR
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'defendant' ->> 'first_name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'defendant' ->> 'last_name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', jsonb_path_query_array(application,  '$.defendants[*].first_name')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', jsonb_path_query_array(application, '$.defendants[*].last_name')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'firm_office' ->> 'name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application ->> 'ufn', '')), 'A') || \
      SETWEIGHT(TO_TSVECTOR('simple', REPLACE(LOWER(COALESCE(application ->> 'laa_reference', '')), '-', '')), 'A')
    VECTOR

    drop_view :searches
    remove_column(:application_version, :search_fields)
    add_column(
      :application_version,
      :search_fields,
      :virtual,
      as: old_search_vector,
      type: :tsvector,
      stored: true
    )
    add_index(:application_version, :search_fields, using: 'gin')
    create_view :searches
  end
end
