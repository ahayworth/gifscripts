#!/usr/bin/env bash

usage() {
  echo "usage: ./sidebyside.sh <file.gif> [NxN]"
  echo
  echo "  Splits a lengthy GIF into a variable number of segments,"
  echo "  and then resizes each segment to a max of 128x128 or a user-provided NxN,"
  echo "  whichever is smaller."
  echo
  echo "  Actual dimensions may be smaller, depending on the dimensions of"
  echo "  the input GIF."
  echo
  echo "  The intended use-case is for displaying multiple emoji in a row"
  echo "  on a messaging service like Slack, eg:"
  echo
  echo "    :emoji-1::emoji-2::emoji-3:"
}

if [[ $# -lt 1 ]] || [[ "$*" =~ ^(--help|-h|-help|-\?)$ ]]; then
  usage
  exit 0
fi

if [[ ! -r $1 ]]; then
  echo "Unable to read $0!"
  exit 1
fi

if [[ ! -w $(pwd) ]]; then
  echo "Unable to write to $(pwd)!"
  exit 1
fi

maxw=128
maxh=128

if [[ ! -z $2 ]]; then
  maxw=$(echo $2 | cut -d 'x' -f 1)
  maxh=$(echo $2 | cut -d 'x' -f 2)
fi

[[ $maxw -gt 128 ]] && maxw=128
[[ $maxh -gt 128 ]] && maxh=128

command -v gifsicle 2>&1 >/dev/null || {
  echo "Cannot find 'gifsicle' binary in your 'PATH'! Is it installed?"
  echo "If it is, try re-running like so:"
  echo 'PATH=$PATH:/path/to/gifsicle ./sidebyside.sh image.gif'
  exit 1
}

total_width=$(gifsicle -I $1 | grep 'logical screen' | awk '{print $3}' | cut -d 'x' -f 1)
total_height=$(gifsicle -I $1 | grep 'logical screen' | awk '{print $3}' | cut -d 'x' -f 2)
nframes=$((($total_width / $maxw) + 1))

echo "Total GIF width: $total_width"
echo "Creating $nframes individual GIFs!"
echo

for i in $(seq 0 $(($nframes - 1))); do
  nhuman=$(($i + 1))
  fhuman="$nhuman-$1"
  x1=$(($maxw * $i))
  x2=$(($x1 + $maxw))
  y1=0
  y2=$total_height
  new_width=$maxh
  [[ $x2 -gt $total_width ]] && x2=$total_width
  [[ $new_width -gt $(($x2 - $x1)) ]] && new_width=$(($x2 - $x1))


  echo "Creating $fhuman..."
  gifsicle --crop $x1,$y1-$x2,$y2 --resize ${new_width}x${maxh} -O3 --no-extensions -o $fhuman $1
done

echo "Done!"
