require 'em-websocket'
require 'json'
require 'redis'
require 'optparse'

options = {
  :binding => 'localhost',
  :port => '8080',
  :rbinding => 'localhost',
  :rport => '6379'
}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby chat_backend.rb [options]"

  opts.on("-b", "--binding=IP", "Binds websocket server to the specified IP.\nDefault: #{options[:binding]}") do |b|
    options[:binding] = b
  end
  opts.on("-p", "--port=port", "Runs webscoket server on the specified port.\nDefault: #{options[:port]}") do |p|
    options[:port] = p
  end
  opts.on("-i", "--redis_binding=IP", "Redis server's IP.\nDefault: #{options[:rbinding]}") do |b|
    options[:rbinding] = b
  end
  opts.on("-P", "--redis_port=port", "Redis server's port'.\nDefault: #{options[:rport]}") do |p|
    options[:rport] = p
  end
end.parse!


module MTYPE
  ERROR = 0
  MESSAGE = 1
  CONNECTED = 2
  DISCONNECTED = 3
end

module FTYPE
  OTHER = 0
  IMAGE = 1
  AUDIO = 2
  VIDEO = 3
end


class EM::WebSocket::Connection
  def remote_addr
    get_peername[2,6].unpack('nC4')[1..4].join('.')
  end

  def set_params(params)
    @self = params
  end

  def self
    @self
  end

  def satisfied_by(p)
    return (@self['target_sex'] == p['sex'] || @self['target_sex'] < 0) &&
            (@self['target_from_age'] <= p['age'] || @self['target_to_age'] < 0) &&
            (@self['target_to_age'] >= p['age'] || @self['target_to_age'] < 0) &&
            (@self['target_locations'].include?(p['location']) || @self['target_locations'].empty?)
  end
end

class Error < StandardError
  attr_accessor :message

  def initialize(message)
    @message = message
  end
end

class ValidateError < Error
end

class ChatError < Error
end

class ChannelError < Error
end


class Channel < EM::Channel
  attr_accessor :key, :clients, :max_size

  def initialize(key, size = 0)
    super()
    @key = key
    @clients = []
    @max_size = size
  end

  def free
    return @max_size > 0 ? @clients.length < @max_size : true
  end

  def connect(ws)
    if !free
      raise ChannelError.new "Channel is full"
    end
    @clients.push(ws)
  end

  def disconnect(ws)
    @clients.delete(ws)
  end
end


def validate_message(msg)
  raise ValidateError.new "['type']" if !msg.has_key?('type')

  if msg['type'] == 0 # system message
    raise ValidateError.new "['data']" if !msg.has_key?('data')
    raise ValidateError.new "['data']['chat']" if !msg['data'].has_key?('chat')
    raise ValidateError.new "['data']['key']" if msg['data']['chat'] == 1 && !msg['data'].has_key?('key')
    if msg['data']['chat'] == 2
      raise ValidateError.new "['data']['sex']" if !msg['data'].has_key?('sex')
      raise ValidateError.new "['data']['age']" if !msg['data'].has_key?('age')
      raise ValidateError.new "['data']['location']" if !msg['data'].has_key?('location')
      raise ValidateError.new "['data']['target_sex']" if !msg['data'].has_key?('target_sex')
      raise ValidateError.new "['data']['target_from_age']" if !msg['data'].has_key?('target_from_age')
      raise ValidateError.new "['data']['target_to_age']" if !msg['data'].has_key?('target_to_age')
      raise ValidateError.new "['data']['target_locations']" if !msg['data'].has_key?('target_locations')
      raise ValidateError.new "['data']['target_locations'] as array" if !msg['data']['target_locations'].kind_of?(Array)
    end
  else # simple message
    raise ValidateError.new "['message']" if !msg.has_key?('message')
  end
end


WSApp = EM.run {
  @redis = Redis.new(:host => options[:rbinding], :port => options[:rport].to_i, :db => 0)
  @expire_time = 86400 # 24 hours
  @max_chat_len = 1000

  @global = Channel.new('global')
  @rooms = []
  @privates = []
  @timers = {}

  def create_channel(key)
    if @redis.exists(key) && @redis.llen(key) == 1
      # TODO: compare ip adresses
      channel = @rooms.push(Channel.new(key)).last
      return channel
    end
    return nil
  end

  def get_all_matches(ws)
    matches = []
    @privates.each do |channel|
      if channel.free && channel.clients.last.satisfied_by(ws.self) && ws.satisfied_by(channel.clients.last.self)
        matches.push(channel)
      end
    end
    return matches
  end

  def find_private(ws)
    matches = get_all_matches(ws)
    return matches.empty? ? nil : matches.sample
  end

  def get_room_channel(key)
    channel_index = @rooms.index{ |c| c.key == key }
    if channel_index
      channel = @rooms[channel_index]
    else
      channel = create_channel(key)
    end
    return channel
  end

  def get_private_channel(ws)
    channel = find_private(ws)
    channel = @privates.push(Channel.new(SecureRandom.hex(5), 2)).last if !channel
    return channel
  end

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
      chat_type = -1
      channel = nil
      sid = 0
      remote_addr = ws.remote_addr

      ws.onclose {
        if channel # if user in channel
          channel.unsubscribe sid
          msg = {type: MTYPE::DISCONNECTED, data: {connected: false, ip: remote_addr, sid: sid, timestamp: Time.now.utc}}
          @redis.rpush channel.key, msg.to_json
          @redis.lpop channel.key if @redis.llen(channel.key) >= @max_chat_len
          channel.push msg
          channel.disconnect ws
          p "User #{remote_addr} with sid #{sid} disconnected from channel #{channel.key}"
          if chat_type > 0 && channel.clients.empty?
            @redis.expire(channel.key, @expire_time)
            if chat_type == 1
              @timers[channel.key] = EM.add_timer 5, proc {
                p "Deleting channel #{channel.key}"
                @rooms.delete(channel)
              }
            end
            if chat_type > 1
              @timers[channel.key] = EM.add_timer 5, proc { 
                @privates.delete(channel)
              }
            end
            p "Channel #{channel.key} is empty and will be removed"
          elsif chat_type > 1
            channel.clients.last.close 1000
          end
        end
      }

      ws.onmessage { |message|
        begin
          msg = JSON.parse(message)
          validate_message(msg)
          
          if msg["type"] == 0
            raise ChatError.new "User already in channel" if channel
            chat_type = msg['data']['chat']
            if chat_type == 0 # global chat
              channel = @global
            elsif chat_type == 1 # room chat
              channel = get_room_channel(msg['data']['key'])
              raise ChatError.new "Bad channel key" if !channel
              cancel_timer channel.key
              @redis.persist channel.key
            else # private chat
              channel = get_private_channel(msg['data'])
              cancel_timer channel.key
              @redis.persist channel.key
            end
            channel.connect ws
            sid = channel.subscribe { |msg|
              ws.send msg.to_json
            }
            p "User #{remote_addr} connected to channel #{channel.key} with sid #{sid}"
            msg = {type: MTYPE::CONNECTED, data: {connected: true, ip: remote_addr, sid: sid, timestamp: Time.now.utc}}
            @redis.rpush channel.key, msg.to_json
            @redis.lpop channel.key if @redis.llen(channel.key) >= @max_chat_len
            channel.push msg
          elsif channel # if user in channel
            msg = {type: MTYPE::MESSAGE, data: {ip: remote_addr, sid: sid, message: msg['message'], timestamp: Time.now.utc}}
            msg[:file] = msg['file'] if msg.has_key?('file')
            @redis.rpush channel.key, msg.to_json
            @redis.lpop channel.key if @redis.llen(channel.key) >= @max_chat_len
            channel.push msg
          else
            raise ChatError.new "Channel is not defined"
          end

        rescue JSON::ParserError
          ws.send JSON.generate({type: MTYPE::ERROR, error: "Invalid JSON"})
        rescue ValidateError => e
          ws.send JSON.generate({type: MTYPE::ERROR, error: "Message must contain field " + e.message})
        rescue ChatError => e
          ws.send JSON.generate({type: MTYPE::ERROR, error: e.message})
        end
      }
    }
  end

  p "WebSocket server started on ws://#{options[:binding]}:#{options[:port]}"
}