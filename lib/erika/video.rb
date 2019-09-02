class Erika
  class Video
    attr_accessor :image
    attr_reader :temp_path, :full_path
    
    def initialize image: nil, full_path: ''
      @image     = image
      @full_path = full_path
      @temp_path = "#{Erika::Default.temp.video_dir}/#{image&.formatted_index}.mp4"
    end
    
    def mix(audio: Erika::Audio.new)
      length_of_video = Erika::Config.slide_duration * Erika::Config.no_of_images.to_f
      length_of_audio = Erika::Runner.(%Q{ffprobe -i #{Erika::Config.audio} -show_format -v quiet | sed -n 's/duration=//p'}).chomp.to_f
      num_of_loops    = (length_of_video / length_of_audio).ceil
      
      if length_of_video > length_of_audio
        # Generate a new audio file looped so that it can cover the video fully
        cmd = %Q{ffmpeg -lavfi "amovie=#{audio.full_path}:loop=#{num_of_loops }" #{Erika::Default.temp.audio_filename}}
        Erika::Runner.(cmd)
      else
        Erika::Runner.("cp #{audio.full_path} #{Erika::Default.temp.audio_filename}")
      end
      
      # ffmpeg has the promising -loop_input flag, but it doesn't support audio inputs yet.
      # Add Background Music to the Slideshow
      cmd = [
          ['ffmpeg'],
          ['-y'],
          ['-i', full_path], # video file as 0th input
          ['-i', Erika::Default.temp.audio_filename], # audio file as 1st input
          [%Q{-vf "subtitles=#{Erika::Default.temp.subtitle_filename}:force_style='Fontsize=#{Erika::Config.caption.font_size},FontName=#{Erika::Config.caption.font},PrimaryColour=#{Erika::Config.caption.font_color}'"}],
          ['-map', '0:v'], # Selects the video from 0th input
          ['-map', '1:a'], # Selects the audio from 1st input
          ['-ac', '2'], # Audio channel manipulation https://trac.ffmpeg.org/wiki/AudioChannelManipulation
          ['-shortest'], # will end the output file whenever the shortest input ends.
          [Erika::Config.output_file]
      ].flatten.join(' ')

      Erika::Runner.(cmd)
    end
    
    def save
      
      # def _create_video_
      #   filename           = image.split('/').last.split('.').first
      later_start_time   = Erika::Config.slide_duration - Erika::Config.slide_animation_duration
      earlier_start_time = 0
      
      if image.index == 0
        # no fading in beginning, but fadeout at end
        transition = %Q{fade=t=out:st=#{later_start_time}:d=#{Erika::Config.slide_animation_duration}}
      elsif image.index == Erika::Config.no_of_images - 1
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
          ['-i', image.temp_path],
          ['-vf', filter],
          ['-c:v', 'mpeg2video'],
          ['-t', Erika::Config.slide_duration],
          ['-q:v', '1'],
          ['-b:a 32k'],
          [temp_path]
      ].join(' ')
      
      Erika::Runner.(cmd)
    end
    
    class << self
      def merge(images)
        images.each do |image|
          cmd = %Q{echo file '#{image.formatted_index}.mp4' >> #{Erika::Default.temp.video_list}}
          Erika::Runner.(cmd)
        end
        
        cmd = %Q{ffmpeg -y -f concat -safe 0 -i #{Erika::Default.temp.video_list} -c copy #{Erika::Default.temp.filename}}
        Erika::Runner.(cmd)
      end
    end
  end
end
