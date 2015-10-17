class Connection

  attr_accessor :id, :ip, :subscribes

  def initialize(id, ip, subscribes=[])
    @id, @ip, @subscribes = id, ip, subscribes
  end

  def subscribe_to(channel)
    channel.subscribe()
  end
end