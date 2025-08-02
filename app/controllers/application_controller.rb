class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Disable CSRF protection for API controllers
  skip_before_action :verify_authenticity_token, if: :api_controller?

  private

  def api_controller?
    controller_path.start_with?('api/')
  end
end
