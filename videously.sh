#!/bin/bash

echo "$(tput setaf 2)Welcome to the wonderful world of automation. $(tput sgr0)"
echo "$(tput setaf 2)Splitting audio and video for processing...$(tput sgr0)"

ffmpeg -i $1 -c:a pcm_s16le -vn -loglevel panic audio.wav
ffmpeg -i $1 -map 0:1 -c:v copy -y -loglevel panic silent.mov

echo "$(tput setaf 2)Analizing audio track for peak volume...$(tput sgr0)"
sox audio.wav -n stat -v 2> vol.txt
vol=`cat vol.txt`

echo "$(tput setaf 2)Processing audio file...$(tput sgr0)"
sox -v "$vol" audio.wav norm.wav

#echo "$(tput setaf 2)Rebuilding $1 as normalized.mp4...$(tput sgr0)"
#ffmpeg -i silent.mov -i norm.wav -map 0:0 -map 1:0 -c:v copy -c:a libfaac -loglevel panic normalized.mp4

echo "$(tput setaf 2)Encoding H.264 qt-faststart file...$(tput sgr0)"

ffmpeg -i silent.mov -i norm.wav -map 0:0 -map 1:0 -c:v libx264 -preset slow -profile:v main -c:a libfaac -movflags +faststart -loglevel info web_normalized_$1

echo "$(tput setaf 2)Cleaning up...$(tput sgr0)"
rm audio.wav
rm norm.wav
rm silent.mov
rm vol.txt

echo "$(tput setaf 2)wOOt!!! Video normalized and encoded $(tput sgr0)"

