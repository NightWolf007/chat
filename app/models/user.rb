class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
          :registerable,
          :rememberable,
          :trackable

  validates :name, presence: true, uniqueness: true
  validates :gender, :inclusion => {:in => [true, false]}
  validates :birthday, presence: true
  validates :location, presence: true

  def age
    Date.today.year - self.birthday.year
  end

  def avatar
    "#{ENV['SERVER_BASE_URL']}/#{ENV['AVATARS_URL']}/#{image}" if image
  end

  before_save :ensure_authentication_token

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).exists?
    end
  end
end
