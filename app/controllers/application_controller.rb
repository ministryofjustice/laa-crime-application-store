class ApplicationController < ActionController::API
  def authenticate!
    head(:unauthorized) unless AuthenticationService.call(request.headers)
  end
end
