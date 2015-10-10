class ApplicationController < ActionController::Base
  respond_to :json

  before_filter :authenticate_user_from_token!

  def upload_avatar(image)
    filename = "#{SecureRandom.hex(5)}.#{image.original_filename.split('.').last}"

    file = image.read
    File.open("#{ENV['AVATARS_DIR']}/#{filename}", 'wb') do |f|
      f.write file
    end

    return filename
  end

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
