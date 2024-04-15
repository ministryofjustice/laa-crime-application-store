module Tokens
  class GenerationService
    class << self
      def call
        access_token.token
      end

      def authentication_required?
        ENV.fetch("AUTHENTICATION_REQUIRED", "true") == "true"
      end

    private

      def oauth_client
        @oauth_client ||= OAuth2::Client.new(
          client_id,
          client_secret,
          token_url: "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token",
        )
      end

      def access_token
        @access_token = new_access_token if @access_token.nil? || @access_token.expired?
        @access_token
      end

      def new_access_token
        oauth_client.client_credentials.get_token(scope: "api://#{client_id}/.default")
      end

      def client_id
        ENV.fetch("APP_CLIENT_ID", "INVALID_CLIENT_ID")
      end

      def tenant_id
        ENV.fetch("TENANT_ID", nil)
      end

      def client_secret
        ENV.fetch("ENTRA_CLIENT_SECRET", "INVALID_SECRET")
      end
    end
  end
end
