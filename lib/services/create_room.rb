module Services
  class CreateRoom

    USERS = 'users:2'
    T_HASH_ROOMS = 'rooms:2' 

    def initialize(params, context)
      @ip = context.request.remote_ip
      @room_type = params[:type]
      @user = get_user
      @params, @context = params, context
    end

    def execute
      uid = @current_user ? @current_user.id : SecureRandom.hex(5)
      if params[:type] == ROOM[:global]
        global_room uid
      elsif params[:type] == ROOM[:private]
        private_room uid
      elsif params[:type] == ROOM[:anonymous]
        anonymous_room uid
      end
    end

    private

    def global_room(uid)
      append_user uid
      context.success 'global'
    end

    def private_room(uid)
      key = generate_s 8
      append_user uid
      context.success key
    end

    def anonymous_room(uid)
      append_user uid
      context.success key
    end

    def append_user(room, uid)
      $redis.hset T_HASH_ROOMS, room, JSON.generate uid: uid, ip: @ip, request_at: Time.now.utc
    end

    def get_user
      if
    end

    def generate_s(len)
      charset = Array('A'..'Z') + Array('a'..'z')
      Array.new(len) { charset.sample }.join
    end
  end
end