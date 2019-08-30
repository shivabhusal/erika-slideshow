
Config = begin
  config_file_path = File.absolute_path('./config.yml', __dir__).to_s
  data = Psych.load_file(config_file_path)
  data.merge({
                 frame_rate:   "1/#{data['slide_duration']}",
                 source_dir:   data['source'].split('/').first,
                 output_dir:   data['output']['filename'].split('/').first,
                 source_files: "#{data['source']}/*.{#{data['file_types'].join(',')}}"
             }).to_o
end

Default = {
    output: {
        dir:      'output',
        filename: 'movie.mp4'
    },
    temp:   {
        dir:               'tmp',
        image_dir:         'tmp/images',
        video_dir:         'tmp/videos',
        image_path:        'tmp/images/%05d.jpg',
        video_path:        'tmp/videos/%05d.mp4',
        video_list:        'tmp/videos/list.txt',
        source:            Erika::Config.source,
        target:            "tmp/#{Erika::Config.source}",
        filename:          "tmp/#{Erika::Config.output.filename.split('/').last}",
        audio_filename:    "tmp/#{Erika::Config.audio.split('/').last}",
        subtitle_filename: "tmp/subtitle.srt"
    }
}.to_o