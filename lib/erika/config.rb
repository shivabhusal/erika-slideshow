class Erika
  Config = begin
    config_file_path = File.absolute_path('../../config.yml', __dir__).to_s
    data             = Psych.load_file(config_file_path)
    root             = `pwd`.chomp
    
    output = $erika_options.output ? File.expand_path($erika_options.output) : "#{root}/#{data['output']['filename']}"
    source = $erika_options.source ? File.expand_path($erika_options.source) : "#{root}/#{data['source']}"
    audio  = $erika_options.audio ? File.expand_path($erika_options.audio) : File.expand_path('../../../library/bensound-ukulele.mp3', __FILE__)
    
    source_files = "#{source}/*.{#{data['file_types'].join(',')}}"
    data.merge({
                   root:         root,
                   no_of_images: Dir[source_files].count,
                   frame_rate:   "1/#{data['slide_duration']}",
                   source_dir:   source,
                   output_dir:   output,
                   source_files: source_files,
                   audio:        audio
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
