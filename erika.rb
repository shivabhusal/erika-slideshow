require 'open3'
require 'psych'
require 'pry'
require './hash'
require './config'
require './string'
require './audio'
require './video'
require './image'
require './runner'

class Erika
  attr_accessor :default, :config, :subtitles
  
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
        `rm -r ./#{Erika::Default.temp.dir}`
        `rm -r ./#{Erika::Config.output_dir}`
        
        `mkdir #{Erika::Config.output_dir}`
        `mkdir #{Erika::Default.temp.dir}`
        `mkdir #{Erika::Default.temp.image_dir}`
        `mkdir #{Erika::Default.temp.video_dir}`
      end
  end
  
  def config
  end
  
  
  private

end

erika = Erika::SlideShow.new
erika.start
