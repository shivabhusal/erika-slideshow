class Erika
  class Image
    attr_accessor :filename, :full_path, :index
    attr_reader :video, :temp_path, :caption, :title, :formatted_index
    
    def initialize filename: '', full_path: '', index: 0
      @filename, @full_path, @index = filename, full_path, index
      @title                        = filename.sentence_case
      @formatted_index              = '%05d' % index
      @temp_path                    = "#{Erika::Default.temp.image_dir}/#{formatted_index}.jpg"
      _gen_caption_
    end
    
    # Chainable method
    def resize_move_to_temp
      cmd = [
          ['ffmpeg'],
          ['-i', full_path.shell_escape],
          ['-vf', _scaling_params_],
          [@temp_path]
      ].flatten.join(' ')
      
      Erika::Runner.(cmd)
      
      self
    end
    
    def create_video
      @video = Erika::Video.new(image: self).save
    end
    
    private
      
      def _scaling_params_
        %Q{"scale=#{Erika::Config.output.width}:#{Erika::Config.output.height}:force_original_aspect_ratio=decrease,pad=#{Erika::Config.output.width}:#{Erika::Config.output.height}:(ow-iw)/2:(oh-ih)/2"}
      end
    
    # 1
    # 00:00:01,600 --> 00:00:04,200
    # English (US)
    #
    # 2
    # 00:00:05,900 --> 00:00:07,999
    # This is a subtitle in American English
      def _gen_caption_
        start_time = _formatted_time(index * Erika::Config.slide_duration) # Seconds
        end_time   = _formatted_time((index + 1) * Erika::Config.slide_duration) # Seconds
        @caption   = [
            '',
            index + 1,
            "#{start_time} --> #{end_time}",
            title,
            ''
        ]
      end
      
      
      def _formatted_time(sec)
        hour = sec / 3600
        min  = (sec - hour * 3600) / 60
        sec  = sec - min * 60
        [hour, min, sec].map { |x| '%02d' % x }.join(':') + ',000'
      end
    
    # def resize_images
    #   prepare_tmp_dir
    #
    #   # Rescale and Pad the images to the center of the frame selected in Erika::Config.yml file
    #   Dir[Erika::Config.source_files].sort.each_with_index do |file, index|
    #
    #     output_filename = output_file(file, formatted_index)
    #
    #
    #     # create_video_for(output_filename, index)
    #
    #   end
    #
    #   # File.write(Erika::Default.temp.subtitle_filename, subtitles.join("\n"))
    # end
  
  end
end

