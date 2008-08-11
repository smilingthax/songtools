#ifndef _TEXTiTEM_H
#define _TEXTiTEM_H
#include <assert.h>
#include <vector>

class AkkordItem {
public:
  enum Tone { TONE_A, TONE_AIS, TONE_B, TONE_C, TONE_CIS, TONE_D, TONE_DIS, TONE_E, TONE_F, TONE_FIS, TONE_G, TONE_GIS,
              TONE_H=TONE_B, TONE_Bb=TONE_AIS, TONE_DES=TONE_CIS, TONE_ES=TONE_DIS, TONE_GES=TONE_FIS, TONE_AS=TONE_GIS, TONE_NONE=-1};
  AkkordItem() :second(NULL),tx_hint(NULL) { }
  AkkordItem(char *akk,bool b_as_h=false) :second(NULL),tx_hint(NULL) { parse(akk,b_as_h); }
  ~AkkordItem() { free(tx_hint); delete second; }
  void parse(char *akk,bool b_as_h=false);
  int set_tone(char tone,bool b_as_h=false);
  int set_base(char tone,bool b_as_h=false);
  int set_type(char t1,char t2);
  const char *get_text(int transpose=0) const;
  void set_text(const char *tx) { free(tx_hint); tx_hint=strdup(tx); }

  enum Only { ONLY_ALL, ONLY_KEY_ALL, ONLY_KEY_BASE, ONLY_KEY_COLOR };
  void set_only(Only master,Only second=ONLY_ALL);

protected:
  bool set_note(char tone,Tone &tin,bool b_as_h);
private:
  bool is_dur;
  Tone note,base;
  char typ1,typ2;
  Only master_only;

  AkkordItem *second;
//9: 2+7; 11: 4+7; 13: 2+4+7

  char *tx_hint;
};

#endif
