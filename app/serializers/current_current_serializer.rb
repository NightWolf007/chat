class CurrentUserSerializer < ActiveModel::Serializer
  attributes :id, :name, :gender, :birthday, :location, :created_at
  attributes :age, :img
  attributes :sign_in_count, 
            :current_sign_in_at, 
            :last_sign_in_at,
            :current_sign_in_ip,
            :last_sign_in_ip
end