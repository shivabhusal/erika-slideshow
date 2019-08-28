require 'open3'
require 'psych'
require 'pry'
#Convert Hash to OpenStruct recursively
class Hash
  def to_o
    JSON.parse to_json, object_class: OpenStruct
  end
end

class Erika
  class << self
    def config
      @config ||= Psych.load_file(File.absolute_path('./config.yml', __dir__).to_s).to_o
    end
  end
  
  def config
    self.class.config
  end
  
  def call
    frame_rate = "1/#{config.slide_duration}"
    cmd = [
        ['ffmpeg'],
        ['-y'],
        ['-r', frame_rate],
        ['-i', config.source],
        ['-c:v', 'libx264'],
        ['-r', '30'], # frame per second,
        ['-pix_fmt', 'yuv420p'],
        [config.output.filename]
    ].flatten.join(' ')
    
    run(cmd)
  end
  
  def resize_images
    prepare_tmp_dir
    
    Dir['images/*.jpg'].each do |file|
      # binding.pry if !matches_ratio?(file)
      # file = __dir__ + '/images/' + file
      # cmd = ['ffmpeg', '-i', file, '-vf', 'scale=640:480', file].join(' ')
      cmd = [
          ['ffmpeg'],
          ['-i', input_file(file)],
          ['-vf', scaling_params(file)],
          [output_file(file)]
      ].flatten.join(' ')
      
      run(cmd)
    end
  end
  
  private
    def run(cmd)
      o, e, s = Open3.capture3(cmd)
      # puts e
    end
    
    def scaling_params(file)
      if aspect_ratio(file) > desired_aspect_ratio
        # No need to set padding
        [%Q{"scale=-1:#{Erika::config.output.width}"}].join(', ')
      else
        [%Q{"scale=-1:#{Erika::config.output.height}}, %Q{pad=#{Erika::config.output.width}:ih:(ow-iw)/2"}].join(', ')
      end
    end
    
    def desired_aspect_ratio
      (config.output.width / config.output.height.to_f)
    end
    
    def matches_ratio?(file)
      aspect_ratio(file) == desired_aspect_ratio
    end
    
    def aspect_ratio(file)
      width, height = get_image_dimension(file)
      width / height.to_f
    end
    
    # @return [width, height]
    def get_image_dimension(file)
      # a = %x(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of default=nw=1 #{file})
      # result = a.match(/([\d]{1,})/)
      a      = `identify -ping -format '%w %h' #{file}`
      result = a.split(' ')
      [result[0].to_i, result[1].to_i]
    end
    
    
    def input_file(input_file)
      # "images/#{input_file}"
      input_file
    end
    
    def output_file(input_file)
      "./tmp/#{input_file}"
    end
    
    def prepare_tmp_dir
      `rm -r ./tmp`
      `rm -r ./output`
      `mkdir output`
      `mkdir tmp`
      `mkdir tmp/images`
    end
end

Erika.new.resize_images
Erika.new.call