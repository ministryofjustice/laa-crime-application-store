module Tokens
  class VerificationService
    class << self
      def call(headers)
        if ENV.fetch("AUTHENTICATION_REQUIRED", "true") == "false"
          return { valid: true, role: headers.fetch("X-Client-Type", "unknown").to_sym }
        end

        jwt = headers["Authorization"].gsub(/^Bearer /, "")
        data = parse(jwt)
        { valid: valid?(data), role: role_from(data) }
      rescue StandardError
        { valid: false, role: nil }
      end

    private

      def parse(jwt)
        JWT.decode(jwt, nil, true, algorithms: "RS256", jwks:)
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
