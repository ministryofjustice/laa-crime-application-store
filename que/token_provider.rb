# frozen_string_literal: true

require 'singleton'
require 'oauth2'

# This class does the heavy lifting of creating a JWT that can be used as a bearer token
class TokenProvider
  include Singleton

  def initialize
    oauth_client
  end

  def oauth_client
    @oauth_client ||= OAuth2::Client.new(
      client_id,
      client_secret,
      token_url: "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token"
    )
  end

  def access_token
    @access_token = new_access_token if @access_token.nil? || @access_token.expired?
    @access_token
  end

  def bearer_token
    access_token.token
  end

  def authentication_configured?
    !tenant_id.nil?
  end

  private

  def new_access_token
    oauth_client.client_credentials.get_token(scope: "api://#{client_id}/.default")
  end

  def client_id
    ENV.fetch('CLIENT_ID', nil)
  end

  def tenant_id
    ENV.fetch('APP_STORE_TENANT_ID', nil)
  end

  def client_secret
    ENV.fetch('CASEWORKER_CLIENT_SECRET', nil)
  end
end
