class RUser

  attr_accessor :id, :ip, :gender, :age, :location

  TABLE_ALLOWED = 'allowed'
  TABLE_BLOCKED = 'blocked'

  class << self

    # get all by room id
    def allowed(rid)
      sallowed = $redis.hkeys "#{TABLE_ALLOWED}:#{rid}"
      sallowed.map do |key|
        suser = $redis.hget "#{TABLE_ALLOWED}:#{rid}", key
        juser = JSON.parse suser
        juser[:id] = key
        new juser
      end
    end

    def jallowed(rid)
      allowed = {}
      sallowed = $redis.hkeys "#{TABLE_ALLOWED}:#{rid}"
      sallowed.each do |key|
        allowed[key] = JSON.parse($redis.hget "#{TABLE_ALLOWED}:#{rid}", key)
      end
    end

    def sallowed(rid)
      allowed = {}
      sallowed = $redis.hkeys "#{TABLE_ALLOWED}:#{rid}"
      sallowed.each do |key|
        allowed[key] = $redis.hget "#{TABLE_ALLOWED}:#{rid}", key
      end
    end

  end

  def initialize(options={})
    @id = options.fetch :id, SecureRandom.hex(4)
    @ip = options.fetch :ip
    @gender = options[:gender]
    @age = options[:age]
    @location = options[:location]
  end

  def allow(rid)
    $redis.hset "#{TABLE_ALLOWED}:#{rid}", @id, to_json
  end

  def to_json
    JSON.generate ip: @ip, gender: @gender, age: @age, location: @location
  end
end