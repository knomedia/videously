#!/bin/bash

input_file=$1
output_file="web_normalized_$input_file"

function welcome() {
  echo "$(tput setaf 2)Welcome to the wonderful world of automation. $(tput sgr0)"
  echo "$(tput setaf 2)Splitting audio and video for processing...$(tput sgr0)"
}

function split_streams() {
  ffmpeg -i $input_file -c:a pcm_s16le -vn -loglevel panic audio.wav
  ffmpeg -i $input_file -c:v copy -y -loglevel panic silent.mov
}


function normalize_audio() {
  echo "$(tput setaf 2)Analyzing audio track for peak volume...$(tput sgr0)"
  sox audio.wav -n stat -v 2> vol.txt
  vol=`cat vol.txt`

  echo "$(tput setaf 2)Processing audio file with a $vol percent boost...$(tput sgr0)"
  sox -v "$vol" audio.wav norm.wav
}

function recompile_audio_video() {
  echo "$(tput setaf 2)Encoding H.264 qt-faststart file...$(tput sgr0)"
  ffmpeg -i silent.mov -i norm.wav -map 0:0 -map 1:0 -c:v libx264 -preset slow -profile:v main -c:a libfaac -movflags +faststart -loglevel info $1
}

function remove_trash() {
  echo "$(tput setaf 2)Cleaning up...$(tput sgr0)"
  rm audio.wav
  rm norm.wav
  rm silent.mov
  rm vol.txt
}

function print_file_size() {
  og_size=`ls -nl $1 | awk '{print $5'}`
  new_size=`ls -nl $2 | awk '{print $5'}`
  savings=$(($og_size - $new_size ))
  percent=$(echo "scale=2; (1-($new_size/$og_size))*100.0" | bc)
  mb=$(echo "scale=2; $savings/1048576.0" | bc) #number is 1024^2
  echo "$(tput setaf 2)Shrunk $1 $mb MB ($percent %)$(tput sgr0)"
}
 
function notify_complete() {
  echo "$(tput setaf 2)wOOt!!! Video normalized and encoded $(tput sgr0)"
}

welcome

split_streams
normalize_audio
recompile_audio_video $output_file
remove_trash
notify_complete
print_file_size $input_file $output_file

