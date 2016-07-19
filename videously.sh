#!/bin/bash


if [ ! -z "$1" ]
then
  input_file=$1
else
  echo "$(tput setaf 1)Sorry my friend. I need at least one file to work with.$(tput sgr0)"
  echo ""
  echo "****************************************"
  echo "videously <input_file> [output_file]"
  echo "****************************************"
  echo ""
  echo "<input_file> file you want to process"
  echo "[output_file] (optional) name to save the new file as"
  echo ""
  exit
fi

if [ ! -z "$2" ]
then
  output_file=$2
else
  raw_file="web_normalized_$input_file"
  output_file="${raw_file%.*}.mp4"
fi

function welcome() {
  echo ""
  echo "$(tput setaf 6)#############################################################"
  echo "   Hey Buddy!!! Welcome to videously."
  echo "#############################################################$(tput sgr0)"
}

function split_streams() {
  echo "$(tput setaf 2)...Splitting audio and video for processing$(tput sgr0)"
  ffmpeg -i $input_file -c:a pcm_s16le -vn -loglevel panic audio.wav
  ffmpeg -i $input_file -vcodec copy -an -loglevel panic silent.mov
}


function normalize_audio() {
  echo "$(tput setaf 2)...Analyzing audio track for peak volume$(tput sgr0)"
  sox audio.wav -n stat -v 2> vol.txt
  vol=`cat vol.txt`

  echo "$(tput setaf 2)...Processing audio file by factor of $vol $(tput sgr0)"
  sox -v $vol -G audio.wav norm.wav
}

function recompile_audio_video() {
  echo "$(tput setaf 2)...Encoding H.264 qt-faststart file...(this could take a while)$(tput sgr0)"
  ffmpeg -i silent.mov -i norm.wav -map 0:0 -map 1:0 -c:v libx264 -preset slow -profile:v main -c:a aac -movflags +faststart -loglevel panic $1
}

function remove_trash() {
  echo "$(tput setaf 2)...Cleaning up$(tput sgr0)"
  rm audio.wav
  rm norm.wav
  rm silent.mov
  rm vol.txt
}

function print_stats() {
  og_size=`ls -nl $1 | awk '{print $5'}`
  new_size=`ls -nl $2 | awk '{print $5'}`
  savings=$(($og_size - $new_size))
  percent=$(echo "scale=2; (1-($new_size/$og_size))*100.0" | bc)
  mb=$(echo "scale=2; $savings/1048576.0" | bc) #number is 1024^2

  echo "$(tput setaf 6)#############################################################"
  echo "$2 is $mb MB ($percent %) smaller"
  echo "Volume was increased by a factor of $vol"
  echo "#############################################################$(tput sgr0)"
  echo ""
}
 
function notify_complete() {
  echo "$(tput setaf 2)...wOOt!!!"
}

welcome

split_streams
normalize_audio
recompile_audio_video $output_file
remove_trash
notify_complete
print_stats $input_file $output_file
