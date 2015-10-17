require 'em-websocket'
require 'json'
require 'redis'
require 'optparse'
require 'byebug'
require '/home/wolf/Projects/Ruby/Rails/chat/app/models/r_models/room'
require '/home/wolf/Projects/Ruby/Rails/chat/app/models/r_models/message'
require '/home/wolf/Projects/Ruby/Rails/chat/app/models/r_models/user'
require '/home/wolf/Projects/Ruby/Rails/chat/app/models/r_models/room_user'

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


class Channel < EM::Channel

  attr_reader :id

  def initialize(id)
    super()
    @id = id
  end

  def subscribe(ws)
    super() do |data|
      data[:room_id] = @id
      data[:timestamp] = Time.now
      ws.send JSON.generate(data)
    end
  end
end

class EM::WebSocket::Connection

  def remote_addr
    get_peername[2,6].unpack('nC4')[1..4].join('.')
  end
end

module MTYPES
  MESSAGE = 0
  SUBSCRIBE = 1
  UNSUBSCRIBE = 2
end

def validate(msg, is_connected)
  return msg['user'] && msg['user']['id'] unless is_connected
  return false unless msg['type']
  if msg['type'] == MTYPES::MESSAGE
    return msg['message'] && msg['room']
  elsif msg['type'] == MTYPES::SUBSCRIBE || msg['type'] == MTYPES::UNSUBSCRIBE
    return !msg['room_user'].nil?
  end
  return false
end


$redis = Redis.new(:host => options[:rbinding], :port => options[:rport].to_i, :db => 0)

WSApp = EM.run do

  ROOM_TTL = 60*60*24

  @channels = {}

  EM::WebSocket.run(:host => options[:binding], :port => options[:port].to_i) do |ws|

    ws.onopen do |handshake|
      p "WebSocket connection open from #{ws.remote_addr}"
      user = nil

      ws.onclose do
        next unless user

        RModels::RoomUser.select_by_user(user.id).each do |ru|
          room = ru.room
          room.expire(ROOM_TTL) if room.empty?
        end
      end

      ws.onmessage do |msg|
        begin
          msg = JSON.parse msg
        rescue JSON::ParserError
          ws.close(4400)
        end

        ws.close(4400) unless validate(msg, !user.nil?)

        unless user
          user = RModels::User.find msg['user']['id']
          ip = ws.remote_addr
          ws.close(4403) unless user && user.ip == ip
          p "Connection opened with #{user.id}:#{ip}"
          next
        end

        if msg['type'] == MTYPES::MESSAGE

          room_user = RModels::RoomUser.find_by_ids(user.id, msg['room']) 
          ws.close(4404) unless room_user

          @channels[room_user.room_id] = Channel.new(room_user.room_id) unless @channels[room_user.room_id]

          @channels[room_user.room_id].push(type: MTYPES::MESSAGE, text: msg['message'], room_user: room_user.id)
          RModels::Message.create(text: msg['message'], room_user_id: room_user.id, room_id: room_user.room_id)

        elsif msg['type'] == MTYPES::SUBSCRIBE

          room_user = RModels::RoomUser.find msg['room_user']
          ws.close(4404) unless room_user
          ws.close(4403) unless room_user.user_id == user.id

          @channels[room_user.room_id] = Channel.new(room_user.room_id) unless @channels[room_user.room_id]
          @channels[room_user.room_id].subscribe(ws)

          p "User #{room_user.name}@#{user.ip} room_user_id=#{room_user.id} subscribed to room #{room_user.room_id}"
          @channels[room_user.room_id].push(type: MTYPES::SUBSCRIBE, room_user: room_user.id)
          room_user.room.persist

        elsif msg['type'] == MTYPES::UNSUBSCRIBE

          room_user = RModels::RoomUser.find msg['room_user']
          ws.close(4404) unless room_user
          ws.close(4403) unless room_user.user_id == user.id

          @channels[room_user.room_id] = Channel.new(room_user.room_id) unless @channels[room_user.room_id]
          @channels[room_user.room_id].unsubscribe(ws)

          p "User #{room_user.name}@#{user.ip} room_user_id=#{room_user.id} unsubscribed to room #{room_user.room_id}"
          @channels[room_user.room_id].push(type: MTYPES::UNSUBSCRIBE, room_user: room_user.id)

          room = room_user.room
          room.expire(ROOM_TTL) if room.empty?

        end
      end
    end
  end

  p "WebSocket server started on ws://#{options[:binding]}:#{options[:port]}"
end