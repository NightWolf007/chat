class ApplicationController < ActionController::Base
  respond_to :json

  before_filter :authenticate_user_from_token!

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
