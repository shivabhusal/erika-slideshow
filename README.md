# video-generator

## Requirements
### ImageMagic
Use ImageMagick® to create, edit, compose, or convert bitmap images. It can read and write images in a variety of formats (over 200) including PNG, JPEG, GIF, HEIC, TIFF, DPX, EXR, WebP, Postscript, PDF, and SVG. Use ImageMagick to resize, flip, mirror, rotate, distort, shear and transform images, adjust image colors, apply various special effects, or draw text, lines, polygons, ellipses and Bézier curves.
#### MacOSx
```bash
brew install imagemagick
```
### FFMPEG
A complete, cross-platform solution to record, convert and stream audio and video.
#### MacOSx
```bash
brew install ffmpeg
```
## Components Used
- get Image dimension
    - [https://stackoverflow.com/a/32824749/3437900](https://stackoverflow.com/a/32824749/3437900)
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
    
- Image to Video Guide FFMPEG
    - [https://en.wikibooks.org/wiki/FFMPEG_An_Intermediate_Guide/image_sequence](https://en.wikibooks.org/wiki/FFMPEG_An_Intermediate_Guide/image_sequence)