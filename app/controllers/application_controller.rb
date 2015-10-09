class ApplicationController < ActionController::Base
  respond_to :json
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  before_filter :authenticate_user_from_token!
  protect_from_forgery with: :null_session

  private

    def authenticate_user_from_token!
      authenticate_with_http_token do |token, options|
        user_name = options[:user_name].presence
        user = user_name && User.find_by_name(user_name)
        token.sub! 'token=', ''
        token.sub! 'name=', 'user_name'
        if user && Devise.secure_compare(user.authentication_token, token)
          sign_in user, store: false
        end
      end
    end
end
