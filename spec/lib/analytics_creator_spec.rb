require "rails_helper"

RSpec.describe AnalyticsCreator do
  let(:commands) { [] }
  # rubocop:disable RSpec/VerifiedDoubles
  let(:mock_response) { double(:mock_response, rows:) }
  # rubocop:enable RSpec/VerifiedDoubles
  let(:rows) { [] }
  let(:views) { [] }

  before do
    allow(ActiveRecord::Base.connection).to receive(:exec_query) do |sql|
      commands << sql
      mock_response
    end
    allow(Scenic.database).to receive(:views).and_return(views)
  end

  describe "#run" do
    context "when user does not exists" do
      it "creates the user account in the public schema" do
        described_class.run

        expect(commands).to eq([
          "select * from pg_catalog.pg_roles where rolname='analytics_user'",
          "CREATE ROLE analytics_user WITH LOGIN PASSWORD 'analytics_user_password'",
          "GRANT CONNECT ON DATABASE laa_crime_application_store_test TO analytics_user",
          "GRANT USAGE ON SCHEMA public TO analytics_user",
          "GRANT SELECT ON failed_imports TO analytics_user",
        ])
      end
    end

    context "when user exists" do
      let(:rows) { [:existing_user] }

      it "creates the user account in the public schema" do
        described_class.run

        expect(commands).to eq(
          [
            "select * from pg_catalog.pg_roles where rolname='analytics_user'",
            "GRANT SELECT ON failed_imports TO analytics_user",
          ],
        )
      end
    end

    context "when views exist" do
      let(:views) { %i[all_events versioned_events] }

      it "creates the user account in the public schema" do
        described_class.run

        expect(commands).to eq([
          "select * from pg_catalog.pg_roles where rolname='analytics_user'",
          "CREATE ROLE analytics_user WITH LOGIN PASSWORD 'analytics_user_password'",
          "GRANT CONNECT ON DATABASE laa_crime_application_store_test TO analytics_user",
          "GRANT USAGE ON SCHEMA public TO analytics_user",
          "GRANT SELECT ON failed_imports TO analytics_user",
          "GRANT SELECT ON all_events TO analytics_user",
          "GRANT SELECT ON versioned_events TO analytics_user",
        ])
      end
    end

    context "when user and views exist" do
      let(:rows) { [:existing_user] }
      let(:views) { %i[all_events versioned_events] }

      it "creates the user account in the public schema" do
        described_class.run

        expect(commands).to eq([
          "select * from pg_catalog.pg_roles where rolname='analytics_user'",
          "GRANT SELECT ON failed_imports TO analytics_user",
          "GRANT SELECT ON all_events TO analytics_user",
          "GRANT SELECT ON versioned_events TO analytics_user",
        ])
      end
    end

    context "when password is blank" do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("ANALYTICS_PASSWORD").and_return("")
      end

      it "raises and error" do
        expect { described_class.run }.to raise_error("ANALYTICS_PASSWORD must be set.")
      end
    end
  end

  describe "#drop_user" do
    context "when user does not exists" do
      it "creates the user account in the public schema" do
        described_class.drop_user

        expect(commands).to eq([
          "select * from pg_catalog.pg_roles where rolname='analytics_user'",
        ])
      end
    end

    context "when user exists" do
      let(:rows) { [:existing_user] }

      it "creates the user account in the public schema" do
        described_class.drop_user

        expect(commands).to eq([
          "select * from pg_catalog.pg_roles where rolname='analytics_user'",
          "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM analytics_user;",
          "REVOKE USAGE ON SCHEMA public FROM analytics_user",
          "ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM analytics_user",
          "REVOKE CONNECT ON DATABASE laa_crime_application_store_test FROM analytics_user",
          "DROP ROLE analytics_user",
        ])
      end
    end
  end
end
