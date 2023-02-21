/* Copyright by Tobias Hoffmann, License: LGPL, see COPYING */
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include "process.h"

void usage(char *pn, int default_tex)
{
  const char *def_impress="impress";
  const char *def_tex="tex and plain";
  const char *def;

  if (default_tex) {
    def = def_tex;
  } else {
    def = def_impress;
  }

  printf("Songprocessor (c) 2004-2013 by Tobias Hoffmann\n\n"
         "Usage: %s [-txphr] [input file]\n"
         "   -t,-x,-p,-l,-i,-S,-j: output tex, html, plain, list, impress, snippet, jsontext\n"
         "   -r: output raw (is always generated, use this switch to suppress fallback to default)\n"
         " If none of the above is given, as default %s will be generated\n\n"
         "Options:\n"
         "   -n: No chords\n"
         "   -N: No show*\n"
         "   -s: Split impress\n"
         "   -A [special]: Allow special\n"
         "   -I [path]: Path for [img]... URIs (only impress)\n"
         "   -P [preset]: Use certain settings (if backend supports it)\n\n"
         "   -h: What you're seeing :-)\n"
         " [input file]: File to input instead of default songs.xml\n",
         pn,def);
}

int main(int argc,char **argv)
{
  char *inputFile="songs.xml";
  int raw=0, o, as_pasr=0;
  process_data_t opts = {};
  const char *imgpath=NULL,*preset=NULL,*special=NULL;

  if (strcmp(argv[0]+strlen(argv[0])-4,"pasr")==0) {
    as_pasr = 1;
  } else {
    as_pasr = 0;
  }

  while ((o=getopt(argc,argv,"tlipjxhrnNSsI:P:A:"))!=-1) {
    switch (o) {
    case 't':
      opts.out_tex = 1;
      break;
    case 'x':
      opts.out_html = 1;
      break;
    case 'p':
      opts.out_plain = 1;
      break;
    case 'l':
      opts.out_list = 1;
      break;
    case 'i':
      opts.out_impress = 1;
      break;
    case 'S':
      opts.out_snippet = 1;
      break;
    case 'j':
      opts.out_jsontext = 1;
      break;
    case 'h':
      usage(argv[0], as_pasr);
      return 1;
    case 'r':
      raw=1;
      break;
    case 'n':
      opts.inter_noakk = 1;
      break;
    case 'N':
      opts.inter_noshow = 1;
      break;
    case 's':
      opts.split_impress = 1;
      break;
    case 'I':
      imgpath=optarg;
      break;
    case 'P':
      preset=optarg;
      break;
    case 'A':
      special=optarg;
      break;
    }
  }
  if ( (!raw)&&
       (!opts.out_tex)&&
       (!opts.out_html)&&
       (!opts.out_plain)&&
       (!opts.out_list)&&
       (!opts.out_impress)&&
       (!opts.out_snippet)&&
       (!opts.out_jsontext) ) {
    // default:
    if (as_pasr) {
      opts.out_tex=1;
      opts.out_plain=1;
      opts.out_list=1;
    } else {
      opts.out_impress=1;
    }
  }
  if (optind<argc) {
    inputFile=argv[optind++];
    if (optind<argc) {
      usage(argv[0], as_pasr);
      return 1;
    }
  }
  return do_process(inputFile, &opts, imgpath, preset, special);
}
