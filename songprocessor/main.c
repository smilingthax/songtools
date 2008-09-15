/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include "process.h"

void usage(char *pn)
{
  const char *def_impress="impress";
  const char *def_tex="tex and plain";
  const char *def=def_impress;

  if (strcmp(pn+strlen(pn)-4,"pasr")==0) {
    def=def_tex;
  }

  printf("Songprocessor (c) 2004-2008 by Tobias Hoffmann\n\n"
         "Usage: %s [-txphr] [input file]\n"
         "   -t,-x,-p,-l,-i: output tex, html, plain, list, impress\n"
         "   -r: output raw (is always generated, use this switch to suppress fallback to default)\n"
         " If none of the above is given, as default %s will be generated\n\n"
         "Options:\n"
         "   -n: No chords\n"
         "   -s: Split impress\n"
         "   -I [path]: Path for [img]... URIs (only impress)\n\n"
         "   -h: What you're seeing :-)\n"
         " [input file]: File to input instead of default songs.xml\n",
         pn,def);
}

int main(int argc,char **argv)
{
  char *inputFile="songs.xml";
  int do_html=0,do_tex=0,do_plain=0,do_list=0,do_impress=0,do_splitimpress=0,raw=0,o,do_noakk=0;
  const char *imgpath=NULL;

  while ((o=getopt(argc,argv,"tlipxhrnsI:"))!=-1) {
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
    case 's':
      do_splitimpress=1;
      break;
    case 'I':
      imgpath=optarg;
      break;
    }
  }
  if ( (!raw)&&(!do_tex)&&(!do_html)&&(!do_plain)&&(!do_list)&&(!do_impress) ) {
    // default: 
    if (strcmp(argv[0]+strlen(argv[0])-4,"pasr")==0) {
      do_tex=1;
      do_plain=1;
      do_list=1;
    } else {
      do_impress=1;
    }
  }
  if (optind<argc) {
    inputFile=argv[optind++];
    if (optind<argc) {
      usage(argv[0]);
      return 1;
    }
  }
  if (do_noakk) {
    return do_process_noakk(inputFile,do_tex,do_plain,do_html,do_list,do_impress,do_splitimpress,imgpath);
  } else {
    return do_process(inputFile,do_tex,do_plain,do_html,do_list,do_impress,do_splitimpress,imgpath);
  }
  return 0;
}
