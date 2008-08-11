#!/bin/sh
FILEDIR=/home/thobi/src/songprocessor/oo-impress/xx

cd $FILEDIR
for i in *.odp; do
  echo "Processing $i"
  ooimpress -invisible "macro:///Standard.Module1.SaveAsPDF($FILEDIR/$i)"
  j=`basename $i .odp`.pdf
  pdftops -level3 -paperw 794 -paperh 595 $j - | ps2pdf - tmp.pdf 
  mv tmp.pdf $j
done 
