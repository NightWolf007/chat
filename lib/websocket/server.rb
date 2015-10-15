require 'em-websocket'
require 'json'
require 'redis'
require 'optparse'
require '/home/wolf/Projects/Ruby/Rails/chat/app/models/r_models/room'
require '/home/wolf/Projects/Ruby/Rails/chat/app/models/r_models/message'
require '/home/wolf/Projects/Ruby/Rails/chat/app/models/r_models/user'

options = {
  :binding => 'localhost',
  :port => '8080',
  :rbinding => 'localhost',
  :rport => '6379'
}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby server.rb [options]"

  opts.on("-b", "--binding=IP", "Binds websocket server to the specified IP.\nDefault: #{options[:binding]}") do |b|
    options[:binding] = b
  end
  opts.on("-p", "--port=port", "Runs webscoket server on the specified port.\nDefault: #{options[:port]}") do |p|
    options[:port] = p
  end
  opts.on("-B", "--redis_binding=IP", "Redis server's IP.\nDefault: #{options[:rbinding]}") do |b|
    options[:rbinding] = b
  end
  opts.on("-P", "--redis_port=port", "Redis server's port'.\nDefault: #{options[:rport]}") do |p|
    options[:rport] = p
  end
end.parse!

class EM::WebSocket::Connection

  def remote_addr
    get_peername[2,6].unpack('nC4')[1..4].join('.')
  end

  def send_error(error)
    send JSON.generate(type: 0, error: error)
  end

  def send_info(name, sid, status)
    send JSON.generate(type: 1, name: name, sid: sid, status: status, timestamp: Time.now)
  end

  def send_message(name, sid, message)
    send JSON.generate(type: 2, name: name, sid: sid, message: message, timestamp: Time.now)
  end
end

def validate(msg, is_connected)
  unless is_connected
    !!(msg['room'] && msg['room']['id'] && msg['user'] && msg['user']['id'])
  else
    !!msg['message']
  end
end


$redis = Redis.new(:host => options[:rbinding], :port => options[:rport].to_i, :db => 0)

WSApp = EM.run {
  ROOM_TTL = 86400 # 24 hours

  @rooms = {}

  EM::WebSocket.run(:host => options[:binding], :port => options[:port].to_i) do |ws|

    ws.onopen { |handshake|
      p "WebSocket connection open from #{ws.remote_addr}"
      room = nil
      user = nil
      sid = 0
      remote_addr = ws.remote_addr

      ws.onclose {
        next unless room

        @rooms[room.id].unsubscribe sid

        @rooms[room.id].push(name: user.name, sid: sid, status: "disconnected")
        p "User #{user.name}@#{remote_addr} with sid #{sid} disconnected from room #{room.id}"

        if room.allowed_ids.empty?
          room.expire(ROOM_TTL)
          @rooms.delete room.id
        end
      }

      ws.onmessage { |msg|
        begin
          msg = JSON.parse msg
        rescue JSON::ParserError
          p "Error on #{remote_addr}: " + "invalid JSON"
          ws.close 4400
          next
        end

        unless validate(msg, !!room)
          p "Error on #{remote_addr}: " + "invalid message"
          ws.close 4400
          next
        end

        # on simple message
        if room
          @rooms[room.id].push(name: user.name, sid: sid, message: msg['message'])
          RModels::Message.new(text: msg['message'], user_id: user.id, room_id: room.id).save
          next
        end

        # on connection message
        room = RModels::Room.find msg['room']['id']

        unless room
          p "Error on #{remote_addr}: " + "room not found"
          ws.close 4404
          next
        end

        user = room.allowed[msg['user']['id']]

        unless user && user.ip == remote_addr
          p "Error on #{remote_addr}: " + "access denied"
          ws.close 4403
          next
        end

        @rooms[room.id] = EM::Channel.new unless @rooms.include? room.id

        sid = @rooms[room.id].subscribe { |data|
          if data[:message]
            ws.send_message(data[:name], data[:sid], data[:message])
          else
            ws.send_info(data[:name], data[:sid], data[:status])
          end
        }

        room.persist # restore expire timer

        p "User #{user.name}@#{remote_addr} connected to room #{room.id} with sid #{sid}"
        @rooms[room.id].push(name: user.name, sid: sid, status: 'connected')
      }
    }
  end

  p "WebSocket server started on ws://#{options[:binding]}:#{options[:port]}"
}