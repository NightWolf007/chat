class RRoom

  TABLE_NAME = 'rooms'

  TYPE = {
    global: 0
    private: 1,
    anonym: 2
  }

  class << self

    def find(id)
      sroom = $redis.hget TABLE_NAME, id
      return nil unless jroom
      jroom = JSON.parse(jroom)
      new jroom[:id], jroom[:type]
    end

  end

  def initialize(type)
    @type = type
    if @type == TYPE[:global]
      @id = 'global'
    elsif @type == TYPE[:private]
      @id = generate_s 8
    else
      @id = SecureRandom.hex 5
    end
  end

  def messages
    $redis.lrange "#{TABLE_NAME}:#{id}:messages", 0, -1
  end

  def users
    $redis.lrange "#{TABLE_NAME}:#{id}:users", 0, -1
  end

  def push_user(user)
    $redis.rpush "#{TABLE_NAME}:#{id}:users", user.to_json
  end

  def push_message(user)
    $redis.rpush "#{TABLE_NAME}:#{id}:messages", message.to_json
  end
end