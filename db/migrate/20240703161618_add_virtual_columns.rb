class AddVirtualColumns < ActiveRecord::Migration[7.1]
  def change
    client_name_vetcor = <<~VECTOR
      to_tsvector('english', application -> 'defendant' ->> 'first_name') || \
      to_tsvector('english', application -> 'defendant' ->> 'last_name') || \
      TO_TSVECTOR(jsonb_path_query_array(application,  '$.defendants[*].first_name')) || \
      TO_TSVECTOR(jsonb_path_query_array(application, '$.defendants[*].last_name'))
    VECTOR

    add_column(
      :application_version,
      :client_name,
      :virtual,
      as: client_name_vetcor,
      type: :tsvector,
      stored: true
    )
    add_column(
      :application_version, :ufn, :virtual,
      as: "(application ->> 'ufn')", type: :string, stored: true
    )
    add_column(
      :application_version, :firm_name, :virtual,
      as: "(application -> 'firm_office' ->> 'name')", type: :string, stored: true
    )
    add_column(
      :application_version, :laa_reference, :virtual,
      as: "(application ->> 'laa_reference')", type: :string, stored: true
    )
    # add_column(
    #   :application, :defendants, :virtual,
    #   as: "json_array_elements(events)", type: :string, stored: true
    # )
  end
end
