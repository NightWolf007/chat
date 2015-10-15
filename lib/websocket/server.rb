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
    msg['room'] && msg['room']['id'] && msg['user'] && msg['user']['id'] && msg['user']['name']
  else
    msg['message'] 
  end
end


$redis = Redis.new(:host => options[:rbinding], :port => options[:rport].to_i, :db => 0)

WSApp = EM.run {
  ROOM_TTL = 86400 # 24 hours
  @max_chat_len = 1000

  @rooms = {}

  def cancel_timer(key)
    if @timers.has_key?(key)
      p "Cancel removing channel #{key}"
      EM.cancel_timer(@timers[key])
      @timers.delete(key)
    end
  end

  EM::WebSocket.run(:host => options[:binding], :port => options[:port].to_i) do |ws|

    ws.onopen { |handshake|
      p "WebSocket connection open from #{ws.remote_addr}"
      room_id = nil
      user_id = nil
      uname = nil
      sid = 0
      remote_addr = ws.remote_addr

      ws.onclose {
        next unless room_id

        @rooms[room_id].unsubscribe sid

        @rooms[room_id].push(name: uname, sid: sid, status: "disconnected")
        p "User #{uname}@#{remote_addr} with sid #{sid} disconnected from room #{room_id}"

        room = RModels.find room_id
        room.expire ROOM_TTL
        # if channel # if user in channel
        #   channel.unsubscribe sid
        #   msg = {type: MTYPE::DISCONNECTED, data: {connected: false, ip: remote_addr, sid: sid, timestamp: Time.now.utc}}
        #   @redis.rpush channel.key, msg.to_json
        #   @redis.lpop channel.key if @redis.llen(channel.key) >= @max_chat_len
        #   channel.push msg
        #   channel.disconnect ws
        #   p "User #{remote_addr} with sid #{sid} disconnected from channel #{channel.key}"
        #   if chat_type > 0 && channel.clients.empty?
        #     @redis.expire(channel.key, @expire_time)
        #     if chat_type == 1
        #       @timers[channel.key] = EM.add_timer 5, proc {
        #         p "Deleting channel #{channel.key}"
        #         @rooms.delete(channel)
        #       }
        #     end
        #     if chat_type > 1
        #       @timers[channel.key] = EM.add_timer 5, proc { 
        #         @privates.delete(channel)
        #       }
        #     end
        #     p "Channel #{channel.key} is empty and will be removed"
        #   elsif chat_type > 1
        #     channel.clients.last.close 1000
        #   end
      }

      ws.onmessage { |msg|
        begin
          msg = JSON.parse msg
        rescue JSON::ParserError
          ws.close 4400
          next
        end

        unless validate(msg, room_id != nil)
          ws.close 4400
          next
        end

        # on simple message
        if room_id
          @rooms[room_id].push(name: uname, sid: sid, message: msg['message'])
          Message.new(text: msg['message'], user_id: user_id, room_id: room_id).save
          next
        end

        # on connection message
        room = RModels::Room.find msg['room']['id']

        unless room
          ws.close 4404
          next
        end

        user = room.allowed.bsearch { |u| u.id == msg['user']['id'] }

        unless user && user.ip == remote_addr
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


        room_id = room.id
        user_id = msg['user']['id']
        uname = msg['user']['name']

        room.persist # restore expire timer

        p "User #{uname}@#{remote_addr} connected to room #{room_id} with sid #{sid}"
        @rooms[room_id].push(name: uname, sid: sid, status: 'connected')
          
        #   if msg["type"] == 0
        #     raise ChatError.new "User already in channel" if channel
        #     chat_type = msg['data']['chat']
        #     if chat_type == 0 # global chat
        #       channel = @global
        #     elsif chat_type == 1 # room chat
        #       channel = get_room_channel(msg['data']['key'])
        #       raise ChatError.new "Bad channel key" if !channel
        #       cancel_timer channel.key
        #       @redis.persist channel.key
        #     else # private chat
        #       channel = get_private_channel(msg['data'])
        #       cancel_timer channel.key
        #       @redis.persist channel.key
        #     end
        #     channel.connect ws
        #     sid = channel.subscribe { |msg|
        #       ws.send msg.to_json
        #     }
        #     p "User #{remote_addr} connected to channel #{channel.key} with sid #{sid}"
        #     msg = {type: MTYPE::CONNECTED, data: {connected: true, ip: remote_addr, sid: sid, timestamp: Time.now.utc}}
        #     @redis.rpush channel.key, msg.to_json
        #     @redis.lpop channel.key if @redis.llen(channel.key) >= @max_chat_len
        #     channel.push msg
        #   elsif channel # if user in channel
        #     msg = {type: MTYPE::MESSAGE, data: {ip: remote_addr, sid: sid, message: msg['message'], timestamp: Time.now.utc}}
        #     msg[:file] = msg['file'] if msg.has_key?('file')
        #     @redis.rpush channel.key, msg.to_json
        #     @redis.lpop channel.key if @redis.llen(channel.key) >= @max_chat_len
        #     channel.push msg
        #   else
        #     raise ChatError.new "Channel is not defined"
        #   end

        # rescue NoMethodError => e
        #   ws.send JSON.generate({type: MTYPE::ERROR, error: "Message must contain field " + e.message})
        # # rescue CWS::ChatError => e
        # #   ws.send JSON.generate({type: MTYPE::ERROR, error: e.message})
        # end
      }
    }
  end

  p "WebSocket server started on ws://#{options[:binding]}:#{options[:port]}"
}