namespace :db do
  desc "Create analytics user and assign permission to all views"
  task config_analytics_user: :environment do
    at_exit { AnalyticsCreator.run }
  end
end

# run db:config_analytics_user before the migrate
# NOTE this will not run on branches that use db:prepare (which calls db:schema:load)
Rake::Task["db:migrate"].enhance(["db:config_analytics_user"])
