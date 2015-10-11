class UploadAvatar

  def initialize(avatar)
    @avatar = avatar
  end

  def execute
    @filename = "#{SecureRandom.hex(5)}.#{@avatar.original_filename.split('.').last}"

    file = @avatar.read
    File.open("#{ENV['AVATARS_DIR']}/#{filename}", 'wb') do |f|
      f.write file
    end
    
    return @filename
  end
end