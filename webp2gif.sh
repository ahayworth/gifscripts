#!/bin/bash

usage() {
  echo "usage: ./webp2gif.sh <file.webp> [file.webp file.webp...]"
  echo "Converts listed webp files to infinite-looping animated gifs."
  echo "If gifsicle is installed, will optimize the converted gif."
  echo
  echo "NB: You must have the imagemagick and webp cli tools available."
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "Try: brew install imagemagick; brew install webp"
  fi
}

for c in webpinfo webpmux dwebp convert; do
  command -v $c 2>&1 >/dev/null || {
    echo "Couldn't find required binary '$c'!"
    echo
    usage
    exit 1
  }
done

if [[ $# -eq 0 ]] || [[ "$*" =~ ^(--help|-h|-help|-\?)$ ]]; then
  usage
  exit 0
fi

for f in "$@"; do
  if [[ ! $f =~ ^(.+)\.webp$ ]]; then
    echo "Skipping '$f'; file does not end in '.webp'"
    continue
  fi

  f_name=$(basename $f)
  f_path=$(realpath $f)
  f_dir=$(dirname $f_path)
  f_size=$(ls -lh $f_name | awk '{ print $5 }')

  pushd $f_dir >/dev/null
  nframes=$(webpinfo -summary $f_name | grep frames | cut -d ' ' -f4)
  delay=$(webpinfo -summary $f_name | grep Duration | head -1 | cut -d ' ' -f4)
  delay=${delay:-10}

  echo "Processing $f:"
  echo "  Frames: $nframes"
  echo "  Inter-frame delay: $delay"
  echo "  Filesize: $f_size"
  echo -n "Extracting frames"

  f_name_png=${f_name//webp/png}
  f_name_gif=${f_name//webp/gif}
  for i in $(seq -f "%05g" 1 $nframes); do
    echo -n "."
    webpmux -get frame $i $f_name -o $f_name.frame-$i >/dev/null 2>&1
    dwebp -quiet $f_name.frame-$i -o $f_name_png.frame-$i >/dev/null 2>&1
  done
  echo "done!"

  echo -n "Converting frames to GIF..."
  convert -quiet $f_name_png.frame-* -delay $delay -loop 0 $f_name_gif
  rm $f_name_png.frame-* $f_name.frame-*
  echo "done!"

  command -v gifsicle 2>&1 >/dev/null && {
    echo -n "Optimizing via gifsicle..."
    gifsicle -O3 --colors 256 -b $f_name_gif
    echo "done!"
  }

  echo "Converted '$f_name to '$f_name_gif'!"
  echo "  $f_name filesize: $f_size"
  echo "  $f_name_gif  filesize: $(ls -lh $f_name_gif | awk '{ print $5 }')"

  echo
  popd > /dev/null
done
