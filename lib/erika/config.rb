class Erika
  TempRoot = File.expand_path('~/erika') # home
  Config = begin
    config_file_path = File.absolute_path('../../config.yml', __dir__).to_s
    data             = Psych.load_file(config_file_path)
    root = `pwd`.chomp
    source_files     = "#{root}/#{data['source']}/*.{#{data['file_types'].join(',')}}"
    data.merge({
                   root:      root   ,
                   no_of_images: Dir[source_files].count,
                   frame_rate:   "1/#{data['slide_duration']}",
                   source_dir:   root + '/' + data['source'].split('/').first,
                   output_dir:   root + '/' + data['output']['filename'].split('/').first,
                   source_files: source_files,
                   audio: root + '/' + data['audio']
               }).to_o
  end
  
  Default = {
      output: {
          dir:      'output',
          filename: 'movie.mp4'
      },
      temp:   {
          dir:               TempRoot + '/tmp',
          image_dir:         TempRoot + '/tmp/images',
          video_dir:         TempRoot + '/tmp/videos',
          image_path:        TempRoot + '/tmp/images/%05d.jpg',
          video_path:        TempRoot + '/tmp/videos/%05d.mp4',
          video_list:        TempRoot + '/tmp/videos/list.txt',
          source:            Erika::Config.source,
          target:            TempRoot + "/tmp/#{Erika::Config.source}",
          filename:          TempRoot + "/tmp/#{Erika::Config.output.filename.split('/').last}",
          audio_filename:    TempRoot + "/tmp/#{Erika::Config.audio.split('/').last}",
          subtitle_filename: TempRoot + "/tmp/subtitle.srt"
      }
  }.to_o

end
