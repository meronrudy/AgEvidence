module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def failure
      redirect_to new_user_session_path, alert: "Authentication failed."
    end

    def passthru
      render plain: "OIDC provider is not configured for this deployment.", status: :not_found
    end
  end
end
