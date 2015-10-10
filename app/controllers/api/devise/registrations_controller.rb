class Api::Devise::RegistrationsController < Devise::RegistrationsController
  before_filter :configure_sign_up_params, only: [:create]
  before_filter :process_avatar, only: [:create]

  protected

  def process_avatar
    if params.has_key?(:user) && params[:user].has_key?(:img)
      params[:user][:image] = upload_avatar(params[:user][:img])
      params[:user].delete(:img)
    else
      params[:user][:image] = nil
    end
  end

  def upload_avatar(image)
    filename = "#{SecureRandom.hex(5)}.#{image.original_filename.split('.').last}"

    file = image.read
    File.open("#{ENV['AVATARS_DIR']}/#{filename}", 'wb') do |f|
      f.write file
    end

    p filename
    return filename
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.for(:sign_up).push :gender, :birthday, :location, :image
  end
  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.for(:sign_up).push :gender, :birthday, :location
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.for(:account_update) << :attribute
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
