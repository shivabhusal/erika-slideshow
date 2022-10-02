class Erika
  class SlideShow
    attr_accessor :images
    
    def initialize
      prepare_tmp_dir
      @images = []
      
      # Gen subtitles
      _images_
    end
    
    def start
      Video.merge(images)
      
      _gen_subtitle_file_
      
      Video.new(full_path: Erika::Default.temp.filename).mix()
    end
    
    private
      
      def _gen_subtitle_file_
        File.write(Erika::Default.temp.subtitle_filename, images.map(&:caption).join("\n"))
      end
      
      def _images_
        Dir[Erika::Config.source_files].sort.each_with_index do |file, index|
          full_path = File.absolute_path(file, __dir__)
          filename  = file.split('/').last.split('.').first
          image     = Erika::Image.new(filename: filename, full_path: full_path, index: index)
          image.resize_move_to_temp.create_video
          images << image
        end
      end
      
      
      def prepare_tmp_dir
        cmds = [
            %Q{rm -r "#{Erika::TempRoot}"},
            %Q{rm -r "#{Erika::Default.temp.dir}"},
            # %Q{rm -r "#{Erika::Config.output_dir}"},
            
            %Q{mkdir "#{Erika::TempRoot}"},
            %Q{mkdir "#{Erika::Default.temp.dir}"},
            %Q{mkdir "#{Erika::Default.temp.image_dir}"},
            %Q{mkdir "#{Erika::Default.temp.video_dir}"},
            
            %Q{mkdir "#{Erika::Config.output_dir}"},
        ]
        
        cmds.each { |cmd| Erika::Runner.(cmd) }
      end
  end
end
