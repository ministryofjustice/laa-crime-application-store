class ApplicationController < ActionController::API
  before_action :authenticate!

  def authenticate!
    head(:unauthorized) unless Tokens::VerificationService.call(request.headers)
  end
end
