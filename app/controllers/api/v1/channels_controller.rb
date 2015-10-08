class Api::V1::ChannelsController < ApplicationControler

  def create
    if !params.has_key?(:type)
      render :status => :bad_request, :json => {}
      return nil
    end
    Services::CreateRoom(params, self).execute
  end

  def show
    if $redis.exists params[:id]
      render :json => {room: {id: params[:id]}}
    else
      render :status => 404, :json => []
    end
  end

  def messages
    if !params.has_key?(:id)
      render :status => :bad_request, :json => []
      return nil
    end
    if !$redis.exists(params[:id])
      render :status => :not_found, :json => []
      return nil
    end
    count = params.has_key?(:count) ? params[:count].to_i : 50
    page = params.has_key?(:page) ? params[:page].to_i : 1
    msgs = $redis.lrange(params[:id], count*(page-1), count*page-1)
    render :json => {messages: msgs.map { |msg| JSON.parse msg }.select { |msg| msg['type'] == 1 }}
  end

  def upload
    # If room don't exists -> 404
    if !$redis.exists params[:id]
      render :status => 404, :json => []
      return nil
    end

    uploads_dir = "public/uploads"
    filename = SecureRandom.hex(5)
    filename += ".#{params[:extension]}" if params.has_key?(:extension) && !params[:extension].empty?
    file_dir = "#{uploads_dir}/#{Date.today.strftime '%m_%d_%Y'}"

    Dir.mkdir file_dir if !Dir.exists?(file_dir)

    file = request.body.read
    File.open("#{file_dir}/#{filename}", 'wb') do |f|
      f.write file
    end

    render :json => {url: "#{request.base_url}/uploads/#{Date.today.strftime '%m_%d_%Y'}/#{filename}"}
  end
end