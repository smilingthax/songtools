/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include <stdio.h>
#include "parseakk.h"
#include "textItem.h"

bool AkkordItem::set_note(char tone,Tone &tin,bool b_as_h)
{
  switch ((tone&0x0f)+0x40) {
    case 'A': tin=TONE_A; break;
    case 'B': if (b_as_h) tin=TONE_B; else tin=TONE_Bb; break;
    case 'C': tin=TONE_C; break;
    case 'D': tin=TONE_D; break;
    case 'E': tin=TONE_E; break;
    case 'F': tin=TONE_F; break;
    case 'G': tin=TONE_G; break;
    case 'H': tin=TONE_H; break;
    default: return false;
  }
  if (tone&0x10) { // flat_or_sharp
    if (tone&0x40) { // sharp
      tin=(Tone)((tin+1)%12);
    } else {
      if (tin!=TONE_Bb) {
        tin=(Tone)((tin-1+12)%12);
      }
    }
  }
  return true;
}

int AkkordItem::set_tone(char tone,bool b_as_h)
{
//  is_sus=is_2=is_4=is_6=is_7=is_maj7=is_dim=key_only=second_rep=false;
  typ1=typ2=0;
  base=TONE_NONE;
  is_dur=!(tone&0x20);
  if (!set_note(tone,note,b_as_h)) {
    return -1;
  }
  return 0;
}

int AkkordItem::set_base(char tone,bool b_as_h)
{
  if (!set_note(tone,base,b_as_h)) {
    return -1;
  }
  return 0;
}

int AkkordItem::set_type(char t1,char t2)
{
  typ1=t1;
  typ2=t2;
  return 0;
}

void AkkordItem::set_only(Only master,Only second)
{
}

bool akkParse(AkkordItem *ai,const char *akk)
{
  int ret=0;
  printf("Pakk[%d]: \"%s\" -> %s\n",ret,akk,ai->get_text());
  return true;
}
