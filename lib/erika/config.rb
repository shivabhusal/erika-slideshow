class Erika
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
                   source_files: source_files
               }).to_o
  end
  
  Default = {
      output: {
          dir:      'output',
          filename: 'movie.mp4'
      },
      temp:   {
          dir:               Config.root + '/tmp',
          image_dir:         Config.root + '/tmp/images',
          video_dir:         Config.root + '/tmp/videos',
          image_path:        Config.root + '/tmp/images/%05d.jpg',
          video_path:        Config.root + '/tmp/videos/%05d.mp4',
          video_list:        Config.root + '/tmp/videos/list.txt',
          source:            Erika::Config.source,
          target:            Config.root + "/tmp/#{Erika::Config.source}",
          filename:          Config.root + "/tmp/#{Erika::Config.output.filename.split('/').last}",
          audio_filename:    Config.root + "/tmp/#{Erika::Config.audio.split('/').last}",
          subtitle_filename: Config.root + "/tmp/subtitle.srt"
      }
  }.to_o

end
