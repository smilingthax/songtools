#ifndef _PTOOLS_H
#define _PTOOLS_H

#include "processor.h"

class normalizeBrTool : public procTool {
public:
  normalizeBrTool(ProcTraverse &parent);
  void openItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item);
  void closeItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item,ProcNodeBufferItem *last);
  void textItem(ProcNodeBufferItem *&item,ProcNodeBufferItem *last);
  int attribItem(ProcNodeBufferItem *item,const xmlChar *name,const xmlChar *value);
  void commentItem(ProcNodeBufferItem *&item);
protected:
  void increment_br(ProcNodeBufferItem *brtag,int no_add=1,int brk_set=-1);
  ProcNodeBufferItem *insert_br(ProcNodeBufferItem *after,int no=-1,int brk=-1);
  ProcNodeBufferItem *kill_last_whitespace();
private:
  int set_bf;
  ProcNodeBufferItem *last_br;
  int may_ignore_nl,empty_line;
};

class substSpacerTool : public procTool {
public:
  substSpacerTool(ProcTraverse &parent);
  void openItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item);
  void closeItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item,ProcNodeBufferItem *last);
  void textItem(ProcNodeBufferItem *&item,ProcNodeBufferItem *last);
  int attribItem(ProcNodeBufferItem *item,const xmlChar *name,const xmlChar *value);
  void commentItem(ProcNodeBufferItem *&item);
protected:
  void count_spacer(const xmlChar *text,int &no,int &skipchars);
private:
  ProcNodeBufferItem *check_for;
};

class substAkkTool : public procTool {
public:
  substAkkTool(ProcTraverse &parent);
  void openItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item);
  void closeItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item,ProcNodeBufferItem *last);
  void textItem(ProcNodeBufferItem *&item,ProcNodeBufferItem *last);
  int attribItem(ProcNodeBufferItem *item,const xmlChar *name,const xmlChar *value);
  void commentItem(ProcNodeBufferItem *&item);
private:
  ProcNodeBufferItem *check_for;
};

class substXlangTool : public procTool {
public:
  substXlangTool(ProcTraverse &parent);
  void openItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item);
  void closeItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item,ProcNodeBufferItem *last);
private:
  bool active;
};

#endif
