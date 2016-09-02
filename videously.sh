#!/bin/bash

function usage() {
  echo "$(tput setaf 1)Need at least an input file to work with.$(tput sgr0)"
  echo ""
  echo "****************************************"
  echo "videously [-a] <input_file> [output_file]"
  echo "****************************************"
  echo ""
  echo "<input_file> file you want to process"
  echo "[output_file] (optional) name to save the new file as"
  echo "adding the -a (audio-only) flag will normalize and convert audio, but apply it back to the same video container without re-encoding"
  echo ""
  exit 2
}

AUDIO_ONLY="false"
# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
while [[ $# -gt 1 ]]
do
  key="$1"

  case $key in
    -i|--input)
      INPUT_FILE="$2"
      shift # past argument
      ;;
    -o|--output)
      OUTPUT_FILE="$2"
      shift # past argument
      ;;
    -a|--audio-only)
      AUDIO_ONLY="true"
      #shift # past argument
      ;;
    --default)
      DEFAULT=YES
      ;;
    *)
      # unknown option
      ;;
  esac
  shift # past argument or value
done


if [ ! ${OUTPUT_FILE} ]; then
  raw_file="web_normalized_$INPUT_FILE"
  OUTPUT_FILE="${raw_file%.*}.mp4"
  if [[ "${AUDIO_ONLY}" == "true" ]]; then
    raw_file="normalized_$INPUT_FILE"
    OUTPUT_FILE="${raw_file}"
  fi
fi

if [[ ! ${INPUT_FILE} ]]; then
  usage
fi
if [[ ! ${OUTPUT_FILE} ]]; then
  usage
fi


function welcome() {
  echo ""
  echo "$(tput setaf 6)#############################################################"
  echo "   Hey Buddy!!! Welcome to videously."
  echo "#############################################################$(tput sgr0)"
}

function split_streams() {
  echo "$(tput setaf 2)...Splitting audio and video for processing$(tput sgr0)"
  ffmpeg -i $INPUT_FILE -c:a pcm_s16le -vn -loglevel panic audio.wav
  ffmpeg -i $INPUT_FILE -vcodec copy -an -loglevel panic silent.mov
}


function normalize_audio() {
  echo "$(tput setaf 2)...Analyzing audio track for peak volume$(tput sgr0)"
  sox audio.wav -n stat -v 2> vol.txt
  vol=`cat vol.txt`

  echo "$(tput setaf 2)...Processing audio file by factor of $vol $(tput sgr0)"
  sox -v $vol -G audio.wav norm.wav
}

function encode_video_audio() {
  echo "$(tput setaf 2)...Encoding H.264 qt-faststart file...(this could take a while)$(tput sgr0)"
  ffmpeg -i silent.mov -i norm.wav -map 0:0 -map 1:0 -c:v libx264 -preset slow -profile:v main -c:a aac -movflags +faststart -loglevel panic $1
}

function merge_video_audio() {
  echo "$(tput setaf 2)...Merging normalized audio with video...(this could take a while)$(tput sgr0)"
  ffmpeg -i silent.mov -i norm.wav -map 0:v -map 1:a -c:v copy -c:a aac -loglevel panic $1
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

if [[ "${AUDIO_ONLY}" == "true" ]];
then
  merge_video_audio $OUTPUT_FILE
else
  encode_video_audio $OUTPUT_FILE
fi

remove_trash
notify_complete
print_stats $INPUT_FILE $OUTPUT_FILE
