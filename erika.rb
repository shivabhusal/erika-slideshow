require 'open3'
require 'psych'
require 'pry'
require './hash'
require './config'
require './string'

class Erika
  attr_accessor :default, :config, :subtitles
  
  class Runner
  
  end
  
  class Image
  
  end
  
  class Video
    def merge
    
    end
  end
  
  class Audio
  
  end
  
  class Subtitle
  
  end
  
  def config
  end
  
  def initialize
    @subtitles = []
    # @default   = 
  end
  
  def call
    # Generate a temporary file with slides only; no music
    # Music will be added later using different command
    # Note: the orders of switches should not be altered
    cmd = %Q{ffmpeg -f concat -safe 0 -i #{Erika::Default.temp.video_list} -c copy #{Erika::Default.temp.filename}}
    
    run(cmd)
    
    length_of_video = Erika::Config.slide_duration * no_of_images.to_f
    length_of_audio = %x{ffprobe -i #{Erika::Config.audio} -show_format -v quiet | sed -n 's/duration=//p'}.chomp.to_f
    num_of_loops    = (length_of_video / length_of_audio).ceil
    
    if length_of_video > length_of_audio
      # Generate a new audio file looped so that it can cover the video fully
      cmd = %Q{ffmpeg -lavfi "amovie=#{Erika::Config.audio}:loop=#{num_of_loops }" #{Erika::Default.temp.audio_filename}}
      run(cmd)
    else
      run("cp #{Erika::Config.audio} #{Erika::Default.temp.audio_filename}")
    end
    
    # ffmpeg has the promising -loop_input flag, but it doesn't support audio inputs yet.
    # Add Background Music to the Slideshow
    cmd = [
        ['ffmpeg'],
        ['-i', Erika::Default.temp.filename], # video file as 0th input
        ['-i', Erika::Default.temp.audio_filename], # audio file as 1st input
        [%Q{-vf "subtitles=#{Erika::Default.temp.subtitle_filename}:force_style='Fontsize=#{Erika::Config.caption.font_size},FontName=#{Erika::Config.caption.font},PrimaryColour=#{Erika::Config.caption.font_color}'"}],
        ['-map', '0:v'], # Selects the video from 0th input
        ['-map', '1:a'], # Selects the audio from 1st input
        ['-ac', '2'], # Audio channel manipulation https://trac.ffmpeg.org/wiki/AudioChannelManipulation
        ['-shortest'], # will end the output file whenever the shortest input ends.
        [Erika::Config.output.filename]
    ].flatten.join(' ')
    
    run(cmd)
  end
  
  def resize_images
    prepare_tmp_dir
    
    # Rescale and Pad the images to the center of the frame selected in Erika::Config.yml file
    Dir[Erika::Config.source_files].sort.each_with_index do |file, index|
      formatted_prefix = '%05d' % index
      output_filename  = output_file(file, formatted_prefix)
      cmd              = [
          ['ffmpeg'],
          ['-i', input_file(file)],
          ['-vf', scaling_params(file)],
          [output_filename]
      ].flatten.join(' ')
      
      run(cmd)
      
      file_name  = file.split('/').last
      file_title = file_name.sentence_case
      
      add_to_subtitle(index, file_title.titleize)
      create_video_for(output_filename, index)
      cmd = %Q{echo file '#{formatted_prefix}.mp4' >> #{Erika::Default.temp.video_list}}
      run(cmd)
    end
    
    File.write(Erika::Default.temp.subtitle_filename, subtitles.join("\n"))
  end
  
  private
    
    def create_video_for(image, index)
      filename           = image.split('/').last.split('.').first
      later_start_time   = Erika::Config.slide_duration - Erika::Config.slide_animation_duration
      earlier_start_time = 0
      
      if index == 0
        # no fading in beginning, but fadeout at end
        transition = %Q{fade=t=out:st=#{later_start_time}:d=#{Erika::Config.slide_animation_duration}}
      elsif index == no_of_images - 1
        # the should be fading in beginning, but no fadeout at end
        transition = %Q{fade=t=in:st=#{earlier_start_time}:d=#{Erika::Config.slide_animation_duration}}
      else
        transition = %Q{fade=t=in:st=#{earlier_start_time}:d=#{Erika::Config.slide_animation_duration},fade=t=out:st=#{later_start_time}:d=#{Erika::Config.slide_animation_duration}}
      end
      filter = %Q{"#{transition}"}
      
      cmd = [
          ['ffmpeg'],
          ['-y', ''],
          ['-loop', '1'],
          ['-i', image],
          ['-vf', filter],
          ['-c:v', 'mpeg2video'],
          ['-t', Erika::Config.slide_duration],
          ['-q:v', '1'],
          ['-b:a 32k'],
          ["#{Erika::Default.temp.video_dir}/#{filename}.mp4"]
      ].join(' ')
      run(cmd)
    end
    
    def no_of_images
      @no_of_images ||= Dir[Erika::Config.source_files].count
    end
    
    # 1
    # 00:00:01,600 --> 00:00:04,200
    # English (US)
    #
    # 2
    # 00:00:05,900 --> 00:00:07,999
    # This is a subtitle in American English
    def add_to_subtitle(index, title)
      start_time = formatted_time(index * Erika::Config.slide_duration) # Seconds
      end_time   = formatted_time((index + 1) * Erika::Config.slide_duration) # Seconds
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
      %Q{"scale=#{Erika::Config.output.width}:#{Erika::Config.output.height}:force_original_aspect_ratio=decrease,pad=#{Erika::Config.output.width}:#{Erika::Config.output.height}:(ow-iw)/2:(oh-ih)/2"}
    end
    
    
    def desired_aspect_ratio
      (Erika::Config.output.width / Erika::Config.output.height.to_f)
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
      filename = input_file.split('/').last
      %Q{#{Erika::Config.source}/"#{filename}"}
    end
    
    def output_file(input_file, formatted_prefix)
      pure_file = input_file.split('/').last
      
      # Something like tmp/images/0001_tomcruise_child.jpg
      "#{Erika::Default.temp.image_dir}/#{formatted_prefix}.jpg"
    end
    
    def prepare_tmp_dir
      `rm -r ./#{Erika::Default.temp.dir}`
      `rm -r ./#{Erika::Config.output_dir}`
      
      `mkdir #{Erika::Config.output_dir}`
      `mkdir #{Erika::Default.temp.dir}`
      `mkdir #{Erika::Default.temp.image_dir}`
      `mkdir #{Erika::Default.temp.video_dir}`
    end
    
    class Transition
    
    end
    
    class Subtitle
    
    end
end

erika = Erika.new
erika.resize_images
erika.call
