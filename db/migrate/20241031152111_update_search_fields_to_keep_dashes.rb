class UpdateSearchFieldsToKeepDashes < ActiveRecord::Migration[7.2]
  def up
    drop_view :searches

    # Drop existing index first
    remove_index :application_version, :search_fields

    # Drop the existing column
    remove_column :application_version, :search_fields

    # Create new search vector without dash stripping
    search_vector = <<~VECTOR
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'defendant' ->> 'first_name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', split_part(COALESCE(application -> 'defendant' ->> 'first_name', ''), '/', 1)), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', split_part(COALESCE(application -> 'defendant' ->> 'first_name', ''), '/', 2)), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'defendant' ->> 'last_name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', split_part(COALESCE(application -> 'defendant' ->> 'last_name', ''), '/', 1)), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', split_part(COALESCE(application -> 'defendant' ->> 'last_name', ''), '/', 2)), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', jsonb_path_query_array(application,  '$.defendants[*].first_name')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', split_part(jsonb_path_query_array(application,  '$.defendants[*].first_name')::text, '/', 1)), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', split_part(jsonb_path_query_array(application,  '$.defendants[*].first_name')::text, '/', 2)), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', jsonb_path_query_array(application, '$.defendants[*].last_name')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', split_part(jsonb_path_query_array(application, '$.defendants[*].last_name')::text, '/', 1)), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', split_part(jsonb_path_query_array(application, '$.defendants[*].last_name')::text, '/', 2)), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'firm_office' ->> 'name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application ->> 'ufn', '')), 'A') || \
      SETWEIGHT(TO_TSVECTOR('simple', LOWER(COALESCE(application ->> 'laa_reference', ''))), 'A')
    VECTOR

    # Add the column back with new definition
    add_column(
      :application_version,
      :search_fields,
      :virtual,
      as: search_vector,
      type: :tsvector,
      stored: true
    )

    # Recreate the index
    add_index(:application_version, :search_fields, using: 'gin')

    create_view :searches, version: 5
  end

  def down
    drop_view :searches

    # Drop existing index
    remove_index :application_version, :search_fields

    # Drop the column
    remove_column :application_version, :search_fields

    # Original search vector with dash stripping
    search_vector = <<~VECTOR
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'defendant' ->> 'first_name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'defendant' ->> 'last_name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', jsonb_path_query_array(application,  '$.defendants[*].first_name')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', jsonb_path_query_array(application, '$.defendants[*].last_name')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application -> 'firm_office' ->> 'name', '')), 'B') || \
      SETWEIGHT(TO_TSVECTOR('simple', COALESCE(application ->> 'ufn', '')), 'A') || \
      SETWEIGHT(TO_TSVECTOR('simple', REPLACE(LOWER(COALESCE(application ->> 'laa_reference', '')), '-', '')), 'A')
    VECTOR

    # Add the column back with original definition
    add_column(
      :application_version,
      :search_fields,
      :virtual,
      as: search_vector,
      type: :tsvector,
      stored: true
    )

    # Recreate the index
    add_index(:application_version, :search_fields, using: 'gin')

    create_view :searches, version: 5
  end
end

