class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  force_ssl if: :production?
  before_action :secure_production

  def production?
    Rails.env.production?
  end

  def secure_production
    if Rails.env.production?
      authenticate_or_request_with_http_basic do |username, password|
        password == 'tri'
      end
    end
  end

end
