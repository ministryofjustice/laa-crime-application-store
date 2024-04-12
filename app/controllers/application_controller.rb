class ApplicationController < ActionController::API
  def authenticate!
    head(:unauthorized) unless Tokens::VerificationService.call(request.headers)
  end
end
