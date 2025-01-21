require "rails_helper"

RSpec.describe "CRM457_2403:backfill_last_updated_at", type: :task do


  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?

  end

  after { Rake::Task["CRM457_2403:backfill_last_updated_at"].reenable }
end
