class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :gender, :birthday, :location, :created_at
  attributes :age, :avatar
end