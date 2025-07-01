module Tokens
  class VerificationService
    class << self
      def call(headers)
        if ENV.fetch("AUTHENTICATION_REQUIRED", "true") == "false"
          return { valid: true, role: headers.fetch("X-Client-Type", "unknown").to_sym, email: "provider@example.com" }
        end

        jwt = headers["Authorization"].gsub(/^Bearer /, "")
        parse(jwt)
      rescue StandardError
        { valid: false, role: nil, email: nil }
      end

    private

      def parse(jwt)
        composite_data = JWT.decode(jwt, provider_secret, true, algorithm: "HS256")

        entra_token = composite_data[0]["entra_token"]
        parsed_token = JWT.decode(entra_token, nil, true, algorithms: %w[RS256], jwks:)
        { valid: valid?(parsed_token), role: role_from(parsed_token), email: composite_data[0]["email"] }
      end

      def valid?(data)
        data[0]["aud"] == client_id &&
          data[0]["iss"] == "https://login.microsoftonline.com/#{tenant_id}/v2.0" &&
          Time.zone.at(data[0]["exp"]) > Time.zone.now
      end

      def jwks
        @jwks ||= JWT::JWK::Set.new(keys)
      end

      def keys
        HTTParty.get(jwks_uri)["keys"]
      end

      def jwks_uri
        config_url = "https://login.microsoftonline.com/#{tenant_id}/.well-known/openid-configuration"
        HTTParty.get(config_url)["jwks_uri"]
      end

      def tenant_id
        ENV.fetch("TENANT_ID", "UNDEFINED_APP_STORE_TENANT_ID")
      end

      def client_id
        ENV.fetch("APP_CLIENT_ID", "UNDEFINED_APP_CLIENT_ID")
      end

      def provider_secret
        ENV.fetch("PROVIDER_CLIENT_SECRET", nil)
      end

      def role_from(data)
        case data.dig(0, "roles", 0)
        when "Provider"
          :provider
        when "Caseworker"
          :caseworker
        else
          raise "Unrecognised roles #{data[0]['roles']}"
        end
      end
    end
  end
end
