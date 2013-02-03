# videously 

Videously is a bash script that relies on `ffmpeg` and `sox` to prepare videos for web delivery. It will normalize the audio within the video container as well as encode the video as an MP4, H.264 video ready for streaming in most browsers and Flash. (Mozilla will still require an Ogg Vorbis, or WebM video... This script does not deal with that).

Currently videously uses the Main profile for H.264. This profile will run in most browsers (Firefox excluding), Flash Player, and iOS devices. Older iOS devices actually require the `baseline` profile.

## Dependencies
* [`ffmpeg`](http://ffmpeg.org/). Make sure you install with H.264 (libx264) and AAC (libfaac) encoders
* [`sox`](http://sox.sourceforge.net/). For normalizing the audio

### Mac OS X / Homebrew users
Installing on Mac OS X for Homebrew users should be pretty easy:

```bash
$ brew install ffmpeg
```

```bash
$ brew install sox
```

It appears that the most recent brew recipe for ffmpeg now includes the needed x264 library for H.264 encoding.

## Usage

```bash
$ ./videously <video_file>
```
Simply execute the script and give it a video to work from. Videosly is non-destructive to your original file. It will create the copies it needs and output a normalized web streaming file based on your given file.

## Tweaking / building your own
While videously works well for my workflow, your results may vary. The following are notes on how to interact with both `ffmpeg` and `sox` for use in tweaking or better understanding what videously is doing.

### Normalize Audio for video files
Notes for creating a shell script to normalize sound in videos

#### Rip the audio into individual file:

```bash
$ ffmpeg -i <input> -c:a pcm_s16le -vn audio.wav
```


#### Rip the video into individual file:

```bash
$ ffmpeg -i <input> -map 0:1 -c:v copy -y silent.mov
```


#### Check available audio level multiplier

```bash
$ sox audio.wav -n stat -v
```

#### Bump up audio level

```bash
$ sox -v <audio_level_mult> audio.wav norm.wav
```


#### Merge files

```bash
$ ffmpeg -i silent.mov -i norm.wav -map 0:0 -map 1:0 -c:v copy -c:a libfaac normalized.mp4
```

#### Clean up temp files

```bash
$ rm audio.wav
$ rm norm.wav
$ rm silent.mov
```


### Notes for ffmpeg, H.264 web encoding

#### The quick and dirty

```bash
ffmpeg -i <input_file> -c:v libx264 -preset slow -profile:v main -c:a copy -movflags +faststart output_file.mp4
```

#### What does that mean?

`-i <input_file>` -- Your input file

`-c:v libx264` -- use the H.264 video codec

`-preset slow` -- slower the better. Options are `ultrafast`, `superfast`, `veryfast`, `faster`, `fast`, `medium`, `slow`, `slower`, `veryslow`

`-profile:v main` -- Options are `baseline`, `main`, `high`. Older iOS only support `baseline`. I have found that `main` works for iPhone 4 and higher.

`-c:a copy` -- Use the existing audio codec. You can substitute this with `libfaac` to ensure that you are getting AAC audio. Generally you capture with that already.

As a side note `libfaac` has the following options:
  
  * `-ac` -- number of audio channels
  * `-ar` -- audio frequency rate in Hz (i.e. `44100`, `48000`, etc)
  * `-ab` -- kilobits per second (i.e `192k`, `128k`, `96k`, etc)

`-movflags +faststart` -- Moves MOOV atom to the beginning of the file

`output_file.mp4` -- The name of your output file.

### Other Options

#### Resizing
You can resize the video passing in the `-s` options with values such as "1024x640". This may require some digging however. At first glance it appears to want to be able to change size into something "divisable by 2". I was able to get it to work by only by cutting video in half, or doubling it. This seems related to needing to set a scale of sorts.


#### Links

Some helpful stuff at: [http://rodrigopolo.com/ffmpeg/cheats.html](http://rodrigopolo.com/ffmpeg/cheats.html)

