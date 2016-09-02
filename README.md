# videously 

Videously is a bash script that relies on `ffmpeg` and `sox` to prepare videos
for web delivery. It will normalize the audio within the video container as
well as encode the video as an MP4, H.264 video ready for streaming in most
browsers (see [caniuse.com](http://caniuse.com/#feat=mpeg4) for details) and Flash.

videously uses the Main profile for H.264. This profile will run in most
browsers, Flash Player, and iOS devices. Really old iOS devices require the
`baseline` profile.

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
$ ./videously.sh -i <video_file> -o <output_file>
```
Simply execute the script and give it a video to work from. Videosly is
non-destructive to your original file. It will create the copies it needs and
output a normalized web streaming file based on your given file. The
`<output_file>` name is optional. If you supply it, videously will
use that name for the file it creates. Without the `<output_file>` it simply
prepends `"web_normalized_"` to the beginning of the file name used as input.


### Audio Normalization Only

Passing a `-a` flag will normalize the audio within your video and create a new
video with the existing video encoding and the new normalized audio. If you
know that video will be processed later by another encoding system, this will
allow you to get normalized audio, without multiple video encodings.

For example

```bash
./videously.sh -a -i source.mov
```


### Making videously globaly available
I generally put tools like this in `/usr/local/bin`. When I do so, I typically
drop the ".sh" from the name for a bash script like this. You can keep the file
where you like. FWIW, it would move it like so:

```bash
$ mv videously.sh /usr/local/bin/videously
```

Doing so allows me to accesses it from any directory like:

```bash
$ videously -i <input_file> -o <output_file>
```

### TODOS

1. Build progress indicator for H.264 encoding (it can take a while on large vids)
2. Put all temporarily generated files into a sub directory so as to not clutter the main directory.
3. Add feature wherein a directory of files could be processed


## Tweaking / building your own
While videously works well for my workflow, your results may vary. The
following are notes on how to interact with both `ffmpeg` and `sox` for use in
tweaking or better understanding what videously is doing.

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

