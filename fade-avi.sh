#!/bin/bash
usage="usage: fade-avi  FROM_IMG  TO_IMG  OUT_AVI [options]
  options:
    -fstep <1-100>    : FADE_STEP = fading speed. larger value is faster (default:1)
    -fclones <0-inf>  : FROM_CLONES = how many copies are put at the beginning? (default:0)
    -offset <0-100>   : OFFSET = initial value of the fading level (default=0)
    -fps <1-1000>     : FPS of the movie (default:50)
    -help             : show this"
source ~/bin/option-parser.sh
set_single_opts help
parse_opts "$@"

if [ `opt help 0` -eq 1 ]; then
  echo "$usage"
  exit 1
fi
if [ ${#fargs[@]} -ne 3 ] ;then
  echo "invalid arguments."
  echo "$usage"
  exit 1
fi

img_from=${fargs[0]}
img_to=${fargs[1]}
out_file=${fargs[2]}

fade_step=`opt fstep 1`
from_clones=`opt fclones 0`
offset=`opt offset 0`
fps=`opt fps 50`


tmp_dir=/tmp/fadeavi$$

# generating fading images...
mkdir $tmp_dir
index=1
if [ $from_clones -gt 0 ];then
  basefile=$tmp_dir/frame`seq -w $index 10000 1000`.jpg
  convert -quality 100 $img_from $basefile
  index=$(($index+1))
  for i in `seq 2 1 $from_clones`; do
    echo -n " $i"
    cp $basefile $tmp_dir/frame`seq -w $index 10000 1000`.jpg
    index=$(($index+1))
  done
fi
tmp_img_from=/tmp/fadeavi$$-from.jpg
convert -quality 100 $img_from $tmp_img_from
for i in `seq $offset $fade_step 100`; do
  echo -n " $i"
  composite -dissolve $i -gravity South $img_to $tmp_img_from -matte \
    $tmp_dir/frame`seq -w $index 10000 1000`.jpg
  index=$(($index+1))
done
rm $tmp_img_from
echo ""

# generating movie encoded with avi...
mencoder "mf://$tmp_dir/frame*.jpg" -mf fps=$fps -ovc lavc -lavcopts vcodec=msmpeg4v2:vbitrate=2400 -o $out_file

rm -r $tmp_dir
echo "$out_file is generated."
