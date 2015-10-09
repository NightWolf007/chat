class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :sex, :birthday, :location, :created_at
end