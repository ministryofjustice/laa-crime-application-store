class ApplicationController < ActionController::API
  include ApplicationHelper

  before_action :authenticate!
  before_action :authorize!

  attr_reader :current_client_role

  def authenticate!
    client_credentials = Tokens::VerificationService.call(request.headers)
    return head(:unauthorized) unless client_credentials[:valid]

    @current_client_role = client_credentials[:role]
  end

  def authorize!
    allowed = AuthorizationService.call(
      @current_client_role,
      controller_name,
      action_name,
      params,
      authorization_object,
    )

    head(:forbidden) unless allowed
  end

  def authorization_object
    nil
  end
end
