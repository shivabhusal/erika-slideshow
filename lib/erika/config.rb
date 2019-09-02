class Erika
  
  class << self
    # @return [dir, file]
    def _get_output_info_from(data, options)
      if options.output
        file_part = options.output.split('/').last
        
        if !file_part.include?('.')
          [File.expand_path(options.output),
           File.expand_path("#{options.output}/#{data['output']['filename'].split('/').last}")]
        elsif file_part.include?('.')
          [File.expand_path(options.output.split('/')[0 .. -2].join('/')),
           File.expand_path(options.output)]
        end
      else
        [File.expand_path(data['output']['filename'].split('/')[0 .. -2].join('/')),
         File.expand_path(data['output']['filename'])]
      end
    end
  end
  
  Config = begin
    config_file_path = File.absolute_path('../../config.yml', __dir__).to_s
    data             = Psych.load_file(config_file_path)
    root             = `pwd`.chomp
    
    output_dir, output_file = _get_output_info_from(data, $erika_options)
    
    source = $erika_options.source ? File.expand_path($erika_options.source) : "#{root}/#{data['source']}"
    audio  = $erika_options.audio ? File.expand_path($erika_options.audio) : File.expand_path('../../../library/bensound-ukulele.mp3', __FILE__)
    
    source_files = "#{source}/*.{#{data['file_types'].join(',')}}"
    data.merge({
                   no_of_images:    Dir[source_files].count,
                   output_dir:      output_dir,
                   output_file:     output_file,
                   source_files:    source_files,
                   audio:           audio,
                   slide_duration:  $erika_options.slide_duration.to_f || data['slide_duration'],
                   slide_animation: $erika_options.transition_duration.to_f || data['slide_animation'],
               }).to_o
  end
  
  TempRoot = File.expand_path('~/erika') # home
  Default  = {
      temp: {
          dir:               TempRoot + '/tmp',
          image_dir:         TempRoot + '/tmp/images',
          video_dir:         TempRoot + '/tmp/videos',
          image_path:        TempRoot + '/tmp/images/%05d.jpg',
          video_path:        TempRoot + '/tmp/videos/%05d.mp4',
          video_list:        TempRoot + '/tmp/videos/list.txt',
          filename:          TempRoot + "/tmp/temp_video.mp4",
          audio_filename:    TempRoot + "/tmp/temp_audio.mp3",
          subtitle_filename: TempRoot + "/tmp/subtitle.srt"
      }
  }.to_o

end
