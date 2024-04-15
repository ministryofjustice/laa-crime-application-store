module Tokens
  class VerificationService
    class << self
      def call(headers)
        return { valid: true, role: :unknown } if ENV.fetch("AUTHENTICATION_REQUIRED", "true") == "false"

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

      def role_from(data)
        case data[0]["aud"]
        when ENV.fetch("PROVIDER_CLIENT_ID")
          :provider
        when ENV.fetch("CASEWORKER_CLIENT_ID")
          :caseworker
        else
          raise "Unrecognised client ID #{data[0]['aud']}"
        end
      end
    end
  end
end
