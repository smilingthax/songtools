#!/usr/bin/perl
$akkdpy=0;

$inakk=0;
while (<>) {
  if      (/<akks(?:| [^>]*)>/) {
    $inakk=1;
  } elsif (/<\/akks>/) {
    $inakk=0;
  } elsif (/<[^>]*>/) {
  } elsif ($inakk) {
    $x=$_;
    $z=$_;
    while (1) {
      if      ($x=~/^[ \t\r\n]*\[([A-Za-z0-9+\-#\/]*)\](.*)$/) {
      } elsif ($x=~/^[ \t\r\n]*\(([A-Za-z0-9+\-#\/]*)\)(.*)$/) {
      } elsif ($x=~/^[ \t\r\n]*([A-Za-z0-9+\-#\/]*)(.*)$/) {
        $y=$1;
        $x=$2;
        last if (!$1);
      }
      $y=$1;
      $x=$2;
      if ($y) {
        if ($akkdpy) {
          if (system("akkdpy -q $y")) {
            print " with ".$y."\n";
          }
        } else {
          print $y."\n";
        }
      }
      last if (!$x);
    }
    print "Rest $x [von $z]\n" if ($x);
  }
}
