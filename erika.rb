require 'open3'
require 'psych'
require 'pry'

#Convert Hash to OpenStruct recursively
class Hash
  def to_o
    JSON.parse to_json, object_class: OpenStruct
  end
end

class String
  def titleize
    self.split.each { |x| x.capitalize! }.join(' ')
  end
end

class Erika
  attr_accessor :default, :config, :subtitles
  class << self
    def config
      config_file_path = File.absolute_path('./config.yml', __dir__).to_s
      @config          ||= begin
        data = Psych.load_file(config_file_path)
        data.merge({
                       frame_rate:   "1/#{data['slide_duration']}",
                       source_dir:   data['source'].split('/').first,
                       output_dir:   data['output']['filename'].split('/').first,
                       source_files: "#{data['source']}/*.{#{data['file_types'].join(',')}}"
                   }).to_o
      end
    end
  end
  
  def initialize
    @subtitles = []
    @config    = self.class.config
    @default   = {
        output: {
            dir:      'output',
            filename: 'movie.mp4'
        },
        temp:   {
            dir:               'tmp',
            image_dir:         'tmp/images',
            image_path:        'tmp/images/%05d.jpg',
            source:            config.source,
            target:            "tmp/#{config.source}",
            filename:          "tmp/#{config.output.filename.split('/').last}",
            audio_filename:    "tmp/#{config.audio.split('/').last}",
            subtitle_filename: "tmp/subtitle.srt"
        }
    }.to_o
  end
  
  def call
    # frame_rate = "1/#{config.slide_duration}"
    # Generate a temporary file with slides only; no music
    # Music will be added later using different command
    # Note: the orders of switches should not be altered
    cmd = [
        ['ffmpeg'],
        ['-r', config.frame_rate],
        ['-i', default.temp.image_path],
        ['-c:v', 'libx264'],
        ['-r', '30'], # frame per second,
        ['-pix_fmt', 'yuv420p'],
        [default.temp.filename]
    ].flatten.join(' ')
    
    run(cmd)
    
    length_of_video = config.slide_duration * no_of_images.to_f
    length_of_audio = %x{ffprobe -i #{config.audio} -show_format -v quiet | sed -n 's/duration=//p'}.chomp.to_f
    num_of_loops    = (length_of_video / length_of_audio).ceil
    
    if length_of_video > length_of_audio
      # Generate a new audio file looped so that it can cover the video fully
      cmd = %Q{ffmpeg -lavfi "amovie=#{config.audio}:loop=#{num_of_loops }" #{default.temp.audio_filename}}
      run(cmd)
    else
      run("cp #{config.audio} #{default.temp.audio_filename}")
    end
    
    # ffmpeg has the promising -loop_input flag, but it doesn't support audio inputs yet.
    # Add Background Music to the Slideshow
    cmd = [
        ['ffmpeg'],
        ['-i', default.temp.filename], # video file as 0th input
        ['-i', default.temp.audio_filename], # audio file as 1st input
        [%Q{-vf "subtitles=#{default.temp.subtitle_filename}:force_style='Fontsize=#{config.caption.font_size},FontName=#{config.caption.font},PrimaryColour=#{config.caption.font_color}'"}],
        ['-map', '0:v'], # Selects the video from 0th input
        ['-map', '1:a'], # Selects the audio from 1st input
        ['-ac', '2'], # Audio channel manipulation https://trac.ffmpeg.org/wiki/AudioChannelManipulation
        ['-shortest'], # will end the output file whenever the shortest input ends.
        [config.output.filename]
    ].flatten.join(' ')
    
    run(cmd)
  end
  
  def resize_images
    prepare_tmp_dir
    
    # Rescale and Pad the images to the center of the frame selected in config.yml file
    Dir[config.source_files].sort.each_with_index do |file, index|
      formatted_prefix = '%05d' % index
      
      cmd = [
          ['ffmpeg'],
          ['-i', input_file(file)],
          ['-vf', scaling_params(file)],
          [output_file(file, formatted_prefix)]
      ].flatten.join(' ')
      
      run(cmd)
      
      file_name                   = file.split('/').last
      file_title                  = file_name.split('.').first.gsub(/\W/, ' ')
      
      add_to_subtitle(index, file_title.titleize)
    end
    
    File.write(default.temp.subtitle_filename, subtitles.join("\n"))
  end
  
  private
    
    def no_of_images
      subtitles.count
    end
    
    # 1
    # 00:00:01,600 --> 00:00:04,200
    # English (US)
    #
    # 2
    # 00:00:05,900 --> 00:00:07,999
    # This is a subtitle in American English
    #
    # 3
    # 00:00:10,000 --> 00:00:14,000
    # Adding subtitles is very easy to do
    
    def add_to_subtitle(index, title)
      start_time = formatted_time(index * config.slide_duration) # Seconds
      end_time   = formatted_time((index + 1) * config.slide_duration) # Seconds
      subtitle   = [
          '',
          index + 1,
          "#{start_time} --> #{end_time}",
          title,
          ''
      ]
      
      subtitles << subtitle
    end
    
    def formatted_time(sec)
      hour = sec / 3600
      min  = (sec - hour * 3600) / 60
      sec  = sec - min * 60
      ms   = '00'
      [hour, min, sec].map { |x| '%02d' % x }.join(':') + ',000'
    end
    
    def run(cmd)
      puts '-' * 100
      puts cmd
      puts '-' * 100
      o, e, s = Open3.capture3(cmd)
      puts e
    end
    
    def scaling_params(file)
      if aspect_ratio(file) > desired_aspect_ratio
        # No need to set padding
        [%Q{"scale=-1:#{config.output.width}"}].join(', ')
      else
        [%Q{"scale=-1:#{config.output.height}}, %Q{pad=#{config.output.width}:ih:(ow-iw)/2"}].join(', ')
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
      dimension = `ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 #{file}`
      result    = dimension.split('x')
      [result[0].to_i, result[1].to_i]
    end
    
    
    def input_file(input_file)
      # "images/#{input_file}"
      %Q{"#{input_file}"}
    end
    
    def output_file(input_file, formatted_prefix)
      pure_file = input_file.split('/').last
      
      # Something like tmp/images/0001_tomcruise_child.jpg
      "#{default.temp.image_dir}/#{formatted_prefix}.jpg"
    end
    
    def prepare_tmp_dir
      `rm -r ./#{default.temp.dir}`
      `rm -r ./#{config.output_dir}`
      `mkdir #{config.output_dir}`
      `mkdir #{default.temp.dir}`
      `mkdir #{default.temp.image_dir}`
    end
    
    class Transition
    
    end
    
    class Subtitle
    
    end
end

erika = Erika.new
erika.resize_images
# binding.pry
erika.call