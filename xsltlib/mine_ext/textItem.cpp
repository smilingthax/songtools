/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "textItem.h"
//#include "parseakk.h"

using namespace std;

void AkkordItem::parse(char *akk,bool b_as_h)
{
  is_dur=true;
#if 0
  akkParse(this,akk);
#endif
}

const char *AkkordItem::get_text(int transpose) const
{
  if (tx_hint) { return tx_hint; }
  // HACK: avoid some sideeffects    TODO: non-static return buffer
  static const char *akname[]={"A","A#","H","C","C#","D","D#","E","F","F#","G","G#"};
  static char retbuf[4][40];
  static int cur_retbuf=0;

  char *ret=retbuf[cur_retbuf];
  cur_retbuf=(cur_retbuf+1)%4;

  transpose%=12;
  if (transpose<0) transpose+=12;
  int pos=0;
  if (!is_dur) {
    ret[pos++]=tolower(akname[(note+transpose)%12][0]);
    ret[pos]=akname[(note+transpose)%12][1];
    if (ret[pos]) pos++;
  } else {
    pos+=sprintf(ret+pos,"%s",akname[(note+transpose)%12]);
  }
  switch (typ1) {
  case -2: pos=strcat(ret+pos,"sus2")-ret; break;
  case -4: pos=strcat(ret+pos,"4")-ret; break;
  case -5:
    if (typ2==1) pos=strcat(ret+pos,"dim")-ret;
    else pos=strcat(ret+pos,"no3")-ret; break;
  case 2: pos=strcat(ret+pos,"add2")-ret; break;
  case 4: pos=strcat(ret+pos,"add4")-ret; break;
  case 6: pos=strcat(ret+pos,"6")-ret; break;
  case 7:
    if (typ2==1) pos=strcat(ret+pos,"maj7")-ret;
    else if (typ2==4) pos=strcat(ret+pos,"7/4")-ret;
    else pos=strcat(ret+pos,"7")-ret; break;
  case 9: pos=strcat(ret+pos,"9")-ret; break;
  case 11: pos=strcat(ret+pos,"11")-ret; break;
  case 13: pos=strcat(ret+pos,"13")-ret; break;
  }
  if (base!=TONE_NONE) {
    pos+=sprintf(ret+pos,"/%s",akname[(base+transpose)%12]);
  }
  return ret;
}
