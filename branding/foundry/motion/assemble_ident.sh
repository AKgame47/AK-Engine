#!/bin/sh
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
cd "$here"
f=1
while [ "$f" -le 73 ]; do
    if [ ! -s "$(printf 'render/frame_%04d.png' "$f")" ]; then
        printf 'Missing Blender frame %s\n' "$f" >&2; exit 1
    fi
    f=$((f+1))
done
ffmpeg -hide_banner -loglevel warning -y -threads 3 -filter_threads 2 \
  -framerate 24 -start_number 1 -i render/frame_%04d.png -i AK-Engine-Ident-Sound.wav \
  -map 0:v:0 -map 1:a:0 \
  -vf 'hqdn3d=2.8:2.0:4.2:3.0,tpad=stop_mode=clone:stop_duration=2,format=yuv420p' \
  -c:v libx264 -threads 4 -preset medium -crf 17 \
  -c:a aac -b:a 192k -ar 48000 -ac 2 -t 5 \
  -movflags +faststart -metadata 'title=AK Engine | Forge Ident' \
  -metadata 'artist=AK Studio' AK-Engine-Forge-Ident.mp4
ffmpeg -hide_banner -v error -i AK-Engine-Forge-Ident.mp4 -f null -
