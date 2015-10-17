require 'em-websocket'

class Channel < EM::Channel

  attr_reader :id

  def initialize(id)
    @id = id
    super
  end

  def subscribe(ws)
    super do |data|
      data[:room_id] = @id
      data[:timestamp] = Time.now
      ws.send data
    end
  end
end