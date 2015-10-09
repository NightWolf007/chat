class RRoom

  attr_accessor :id

  class << self

    def exists(id)
      $redis.exists "#{RUser::TABLE_ALLOWED}:#{id}"
    end

  end

  def initialize(options={})
    @id = options.fetch :id, SecureRandom.hex(4)
  end

  def messages
    RMessage.select @id
  end

  def allowed
    RUser.allowed @id
  end

  def allow(user)
    user.allow @id
  end
end