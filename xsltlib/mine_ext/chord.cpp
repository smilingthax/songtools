#include "chord.h"
#include <string.h>
#include <assert.h>
#include <stdexcept>
 #include <stdio.h>

// TODO/IDEA: allow spec of #/b  (problem? out-of-key chords?)

//#define NORMALIZE_MINOR    // (to uppercase; - also normalizes base to uppercase)

struct note_info {
  const char *name;
  int tune; // C=0
};

static const note_info note_names[]={
  // longer match first!
  {"Cb", ~11}, {"C#", 1}, {"C", 0},  // ~x  -> forbidden...
  {"Db", 1}, {"D#", 3}, {"D", 2},
  {"Eb", 3}, {"E#", ~5}, {"E", 4},
  {"Fb", ~4}, {"F#", 6}, {"F", 5},
  {"Gb", 6}, {"G#", 8}, {"G", 7},
  {"Ab", 8}, {"A#", 10}, {"A", 9},
  {"Bb", 10}, {"B#", ~0}, {"B", 11/* ? */},
  {"H#", ~0}, {"H", 11},
  {NULL, -1}
};

static const note_info *is_note(const char *str) // {{{
{
  if ( (*str=='b')&&(str[1]!='b') ) {
    return NULL;
  }
  int iA;
  for (iA=0; note_names[iA].name;iA++) {
    if (strncasecmp(note_names[iA].name,str,note_names[iA].name[1] ? 2:1)==0) {
if (iA==20) fprintf(stderr,"Warning: B found (normalized to H)\n"); // TODO/FIXME ...
      return note_names+iA;
    }
  }
  return NULL;
}
// }}}

static const bool stdflat[]={0,0,0,1,0,0,0,0,0,0,1,0}; // Eb and Bb

static const char *transpose_one(const note_info &note,char orig_case,int transpose,char force=0) // {{{
{
  static const char *lower[]={"c","db","d","eb","e","f","gb","g","ab","a","bb","h",
                              "c","c#","d","d#","e","f","f#","g","g#","a","a#","h"};
  static const char *upper[]={"C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","H",
                              "C","C#","D","D#","E","F","F#","G","G#","A","A#","H"};

  // assert(transpose>=-12);
  int tune=(note.tune+transpose+12)%12;
if (note.tune<0) {
  // esp.: not supported in sp_liner (TODO?)
  fprintf(stderr,"Warning: E#, Fb, B#/H# or Cb is not supported\n");
  tune=(~note.tune+transpose)%12;
}
  if (transpose==0) {
    if (note.name[1]=='#') {
      tune+=12;
    } // else: use b
  } else if (force) {  // e.g. for F#/A#  [not: F#/Bb]
    if (force=='#') {
      tune+=12;
    } // else: use b
  } else if (!stdflat[tune]) { // not perfect (but e.g. F# major would theoretically need E# [but it's "just" E#dim or C#/E# or A#m/E#, ...] ...)
    tune+=12;
  }

  if (orig_case!=note.name[0]) {
    return lower[tune];
  } else {
    return upper[tune];
  }
}
// }}}

std::string transpose_chord(const char *str, int transpose) // {{{
{
  assert( (transpose>-12)&&(transpose<=12) );  // TODO?  ...+transpose+... -> ...+transpose%12+... (in transpose_one())

  // we try to parse str (or error out) even when transpose==0
  std::string ret;
  enum { INIT, HAS_NOTE, HAS_BASE } mode=INIT;
  char force=0;

  const char *tmp=str;
  while (1) {
    const int next=strcspn(tmp,"()[]/");
    if (next) {
      const note_info *note=is_note(tmp);
      if (note) {
#ifndef NORMALIZE_MINOR
        const char *tn=transpose_one(*note,*tmp,transpose);
        ret.append(tn);
#else
        const char *tn=transpose_one(*note,note->name[0],transpose);
        ret.append(tn);
        if (note->name[0]!=*tmp) {
          ret.push_back('m');
        }
#endif
        mode=HAS_NOTE;
        force=tn[1];

        const int len=note->name[1] ? 2:1;
        ret.append(tmp+len,next-len);
      } else if (mode==INIT) {
        throw std::runtime_error("Expected note");
      } else { // color
        ret.append(tmp,next);
      }
      tmp+=next;
    }

    if (!*tmp) {
      break;
    } else if (*tmp=='/') {
      if (mode==HAS_BASE) {
        throw std::runtime_error("Unexpected '/' after bass note");
      }
      ret.push_back(*tmp);
      tmp++;
      const note_info *base=is_note(tmp);
      if (base) {
#ifndef NORMALIZE_MINOR
        ret.append(transpose_one(*base,*tmp,transpose,force));
#else
        ret.append(transpose_one(*base,base->name[0],transpose,force));
#endif
        tmp+=base->name[1] ? 2:1;
        mode=HAS_BASE;
      } else if (mode==INIT) {
        throw std::runtime_error("Expected bass note");
      } // else: part of color
    } else {
      if ( (*tmp==')')||(*tmp==']') ) {
        mode=INIT;
        force=0;
      }
      ret.push_back(*tmp);
      tmp++;
    }
  }

//printf("%s %s\n",str,ret.c_str());
#ifndef NORMALIZE_MINOR
assert( (transpose!=0)||(strcmp(ret.c_str(),str)==0)||(ret=="H") );
#endif
  return ret;
}
// }}}

