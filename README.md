# video-generator
This is tested in macOS Mojave `10.14.6 (18G87)`

## Installation
Please make sure you install `FFMPEG` library in your machine before using this gem.


```bash
    gem install erika   

```
## Requirements
### FFMPEG
A complete, cross-platform solution to record, convert and stream audio and video.
#### MacOSx
```bash
brew install ffmpeg
```

#### Ubuntu
```bash
apt-get install ffmpeg
```


## Usage
To compile images in `~/pictures/birthday`, you need to make sure files are named in proper order. 
I recommend you to prefix the files with number like
```
- 0 My first birthday.jpg
- 1 My second birthday.jpg
- 2 My second birthday.jpg
- 3 My third birthday.jpg
```

single command to compile
```bash
cd ~/pictures

erika g -s birthday -o mybirthday.mp4 

# This will generate video called `mybirthday.mp4`
```

## Options
```bash
 erika help g
Usage:
  erika g

Options:
  -o, [--output=OUTPUT]                            # Output path; where to generate output movie
  -s, [--source=SOURCE]                            # Input path; folder path where the images are located
  -a, [--audio=AUDIO]                              # Audio path; the path to bg audio
  -t, [--transition-duration=TRANSITION_DURATION]  # Transition animation duration between two images
  -S, [--slide-duration=SLIDE_DURATION]            # Slide duration between two images

Generate movie

```
Example:-

```ruby
 erika g -s happy -S=5 -t=4 -o=opt/mymovie.mp4

```

## How Slide Animation is implemented
Creating intermediate mpeg's for each image and then concatenate them
 all into a `video`. 
 
**For example**, say you have `5` images; you would run this for each one of the 
 images to create the intermediate mpeg's with a fade in at the beginning and a fade out at the end.

```bash
ffmpeg -y -loop 1 -i <your-image> -vf "fade=t=in:st=0:d=0.5,fade=t=out:st=4.5:d=0.5" -c:v mpeg2video -t 5 -q:v 1 image-1.mpeg
```

where `t` is the duration, or time, of each image. Once you have all of these mpeg's, you use
 ffmpeg's concat command to combine them all into an `mp4`.

```bash
ffmpeg -y -i image-1.mpeg -i image-2.mpeg -i image-3.mpeg -i image-4.mpeg -i image-5.mpeg -filter_complex '[0:v][1:v][2:v][3:v][4:v] concat=n=5:v=1 [v]' -map '[v]' -c:v libx264 -s 1280x720 -aspect 16:9 -q:v 1 -pix_fmt yuv420p output.mp4
```

## Components Used
- get Image dimension
    - [https://stackoverflow.com/a/32824749/3437900](https://stackoverflow.com/a/32824749/3437900)
    - [https://askubuntu.com/a/577431](https://askubuntu.com/a/577431)
- IMAGE SCALING
    - [https://www.bogotobogo.com/FFMpeg/ffmpeg_image_scaling_jpeg.php](https://www.bogotobogo.com/FFMpeg/ffmpeg_image_scaling_jpeg.php)
- FFMPEG filters
    - [https://ffmpeg.org/ffmpeg-filters.html#subtitles-1](https://ffmpeg.org/ffmpeg-filters.html#subtitles-1)
    
- Resizing and padding image
    - [https://superuser.com/a/991412](https://superuser.com/a/991412)
    
- Capturing STD Streams to prevent logs being cluttered
    - [https://ruby-doc.org/stdlib-1.9.3/libdoc/open3/rdoc/Open3.html#method-c-capture3](https://ruby-doc.org/stdlib-1.9.3/libdoc/open3/rdoc/Open3.html#method-c-capture3)
- Animation in Slide Transition
    - [https://stackoverflow.com/questions/30974848/animation-between-images-using-ffmpeg](https://stackoverflow.com/questions/30974848/animation-between-images-using-ffmpeg)
    - [https://superuser.com/questions/833232/create-video-with-5-images-with-fadein-out-effect-in-ffmpeg/834035#834035](https://superuser.com/questions/833232/create-video-with-5-images-with-fadein-out-effect-in-ffmpeg/834035#834035)
- Image to Video Guide FFMPEG
    - [https://en.wikibooks.org/wiki/FFMPEG_An_Intermediate_Guide/image_sequence](https://en.wikibooks.org/wiki/FFMPEG_An_Intermediate_Guide/image_sequence)
- Repeat Audio and generate a new audio file
    - [https://stackoverflow.com/a/8017021/3437900](https://stackoverflow.com/a/8017021/3437900)
- Add Subtitles to the video
    - [https://trac.ffmpeg.org/wiki/HowToBurnSubtitlesIntoVideo](https://trac.ffmpeg.org/wiki/HowToBurnSubtitlesIntoVideo)
    
    https://superuser.com/questions/547296/resizing-videos-with-ffmpeg-avconv-to-fit-into-static-sized-player/1136305#1136305
    https://trac.ffmpeg.org/wiki/Concatenate