# ActiveRecord doesn't know how to handle postgis interna tables properly, and will by default
# include them in the schema file, which means it will then try to _delete_ them when doing
# rails db:prepare, which will then blow up.

# The correct way to deal with this is to install activerecord-postgis-adapter and update
# the adaptor in database.yml to "postgis". However, that gem doesn't yet work with Rails 8,
# so until that is fixed (https://github.com/rgeo/activerecord-postgis-adapter/pull/419),
# we can work around it by telling ActiveRecord to ignore postgis tables as follows:
ActiveRecord::SchemaDumper.ignore_tables = %w[spatial_ref_sys geometry_columns geography_columns]
