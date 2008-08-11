/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include <stdio.h>
#include <unistd.h>
#include "process.h"

void usage(char *pn)
{
  printf("Songprocessor (c) 2004-2007 by Tobias Hoffmann\n\n"
         "Usage: %s [-txphr] [input file]\n"
         "   -t,-x,-p,-l,-i: output tex, html, plain, list, impress\n"
         "   -r: output raw (is always generated, use this switch to suppress fallback to default)\n"
#ifdef DEFAULT_IMPRESS
         " If none of the above is given, as default impress will be generated\n"
#else
         " If none of the above is given, as default tex and plain will be generated\n"
#endif
//         "   -n: No akkords\n"
         "   -h: What you're seeing :-)\n"
         " [input file]: File to input instead of default songs.xml\n",pn);
}

int main(int argc,char **argv)
{
  char *inputFile="songs.xml";
  int do_html=0,do_tex=0,do_plain=0,do_list=0,do_impress=0,raw=0,o,do_noakk=0;

  while ((o=getopt(argc,argv,"tlipxhrn"))!=-1) {
    switch (o) {
    case 't':
      do_tex=1;
      break;
    case 'x':
      do_html=1;
      break;
    case 'p':
      do_plain=1;
      break;
    case 'l':
      do_list=1;
      break;
    case 'i':
      do_impress=1;
      break;
    case 'h':
      usage(argv[0]);
      return 1;
    case 'r':
      raw=1;
      break;
    case 'n':
      do_noakk=1;
      break;
    }
  }
  if ( (!raw)&&(!do_tex)&&(!do_html)&&(!do_plain)&&(!do_list)&&(!do_impress) ) {
    // default: 
#ifdef DEFAULT_IMPRESS
    do_impress=1;
#else
    do_tex=1;
    do_plain=1;
    do_list=1;
#endif
  }
  if (optind<argc) {
    inputFile=argv[optind++];
    if (optind<argc) {
      usage(argv[0]);
      return 1;
    }
  }
  if (do_noakk) {
    do_process_noakk(inputFile,do_tex,do_plain,do_html,do_list,do_impress);
  } else {
    do_process(inputFile,do_tex,do_plain,do_html,do_list,do_impress);
  }
  return 0;
}
