module RModels

  class RoomUser

    attr_accessor :id, :room_id, :user_id, :name, :image, :gender, :age, :location

    TABLE_NAME = 'room_users'

    class << self

      def find(id)
        return nil unless RoomUser.exists(id)
        data = $redis.get "#{TABLE_NAME}:#{id}"
        jdata = JSON.parse(data)
        RoomUser.new(id: id, room_id: jdata['room_id'], user_id: jdata['user_id'],
                    name: jdata['name'], image: jdata['image'], 
                    gender: jdata['gender'], age: jdata[:age], location: jdata[:location])
      end

      def find_by_ids(user_id, room_id)
        room_users = all
        index = room_users.index { |ru| ru.user_id == user_id && ru.room_id == room_id }
        return nil unless index
        room_users[index]
      end

      def all
        all_ids.map do |id|
          RoomUser.find id
        end
      end

      def all_ids
        keys = $redis.keys "#{TABLE_NAME}:*"
        keys.map do |k|
          k = k[TABLE_NAME.length+1..-1]
        end
      end

      def exists(id)
        $redis.exists "#{TABLE_NAME}:#{id}"
      end

      def create(options)
        RoomUser.new(options).save
      end

      def select_by_user(user_id)
        all.select { |ru| ru.user_id == user_id}
      end

      def select_by_room(room_id)
        all.select { |ru| ru.room_id == room_id}
      end

    end

    def initialize(options={})
      @id = options.fetch(:id, SecureRandom.hex(5))
      @room_id = options.fetch :room_id
      @user_id = options.fetch :user_id
      @name = options[:name]
      @image = options[:image]
      @gender = options[:gender]
      @age = options[:age]
      @location = options[:location]
    end

    def user
      User.find @user_id
    end

    def room
      Room.find @room_id
    end

    def save
      $redis.set "#{TABLE_NAME}:#{@id}", to_json
      return self
    end

    def avatar
      "#{ENV['SERVER_BASE_URL']}/#{ENV['AVATARS_URL']}/#{@image}" if @image
    end

    def to_json
      JSON.generate(room_id: @room_id, user_id: @user_id, name: @name, image: @image,
                  gender: @gender, age: @age, location: @location)
    end

    def expire(ttl)
      $redis.expire "#{TABLE_NAME}:#{@id}", ttl
    end

    def persist
      $redis.persist "#{TABLE_NAME}:#{@id}"
    end
  end

end