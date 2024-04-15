class ApplicationController < ActionController::API
  before_action :authenticate!

  attr_reader :current_client_role

  def authenticate!
    client_credentials = Tokens::VerificationService.call(request.headers)
    return head(:unauthorized) unless client_credentials[:valid]

    @current_client_role = client_credentials[:role]
  end
end
