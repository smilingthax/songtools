#!/bin/sh
FILEDIR=/home/thobi/src/songprocessor

if [ -n "$1" ]; then
  if [ $PWD != $FILEDIR ]; then
    echo "Bad directory. Must be in $FILEDIR"
    exit 1
  fi
  DST=`dirname "$1"`/`basename "$1" .xml`
  ./pasr -i "$1" || exit 2
fi

cd $FILEDIR
i=allimpress.odp
echo "Processing $i"
soffice -headless "macro:///Standard.Module1.SaveAsPDF($FILEDIR/$i)"
echo "Minimizing"
sleep 1
j=`basename $i .odp`.pdf
pdftops -level3 -paperw 794 -paperh 595 $j - | ps2pdf - _tmp.pdf
mv _tmp.pdf $j

if [ -n "$1" ]; then
  if [ -f $DST.odp ] || [ -f $DST.pdf ]; then 
    echo "$DST.odp or $DST.pdf exists. overwrite?"
    read a
    if [ "$a" != "y" ]; then
      echo "Not overwritten"
      exit 0
    fi
  fi
  cp $i $DST.odp 
  cp $j $DST.pdf
fi
