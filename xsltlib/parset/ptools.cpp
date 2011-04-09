/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include <assert.h>
#include <string.h>
#include "ptools.h"

using namespace std;

// {{{ normalizeBrTool
normalizeBrTool::normalizeBrTool(ProcTraverse &parent) : procTool(parent),set_bf(-1),last_br(NULL),may_ignore_nl(1),empty_line(1)
{
}

void normalizeBrTool::increment_br(ProcNodeBufferItem *brtag,int no_add,int brk_set)
{
  assert((brtag)&&(brtag->is_br()));
  if (no_add!=0) {
    if (brtag->no==-1) {
      brtag->no=1;
    }
    brtag->no+=no_add;
    if (brtag->no<0) {
      brtag->no=0;
    }
  }
  if (brk_set!=-1) {
    brtag->brk=brk_set;
  }
}

ProcNodeBufferItem *normalizeBrTool::insert_br(ProcNodeBufferItem *after,int no,int brk)
{
  ProcNodeBufferItem *item;
  item=new ProcNodeBufferItem((const xmlChar *)"br");
  item->type=ProcNodeBufferItem::NODE_BR;
  if (no>-1) { 
    item->no=no;
  }
  if (brk!=-1) {
    item->brk=brk;
  }
  parent.move(after,item,item);  // TODO? check for validity of br tag at the insert position 
  return item;
}

ProcNodeBufferItem *normalizeBrTool::kill_last_whitespace()
{
  if ( (parent.last)&&(parent.last->is_text()) ) {
    if ( (parent.last->value)&&(iswhitespace(parent.last->value)) ) {
      parent.pop();
/*
    } else if (parent.last->value) { // delete trailing WS // value!=0 always // TODO? what with \n looses formatting
      xmlChar *str=parent.last->value,*tmp;
      for (tmp=str;*str;str++) {
        if (!iswhitenl(*str)) {
          tmp=str+1;
        }
      }
      *tmp=0;
*/
    }
  }
  return parent.last;
}

void normalizeBrTool::openItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item)
{
  if (tag==ProcTraverse::BLOCK_TAG) {
    may_ignore_nl=1;
    last_br=NULL;
  } else if (tag==ProcTraverse::BR_TAG) {
    kill_last_whitespace();
    if (may_ignore_nl) {
      if ( (last_br)&&(set_bf!=-1) ) {
        increment_br(last_br,0,set_bf);
      }
      delete item;
      item=NULL;
      may_ignore_nl--;
    } else if (last_br) { // join br's
      delete item;
      item=NULL;
      increment_br(last_br,1,set_bf);
    } else { // generate new item
      item->type=ProcNodeBufferItem::NODE_BR;
      item->unclosed_empty=true;
      if (set_bf!=-1) {
        item->brk=set_bf;
      }
      last_br=item;
    }
    empty_line=1;
    set_bf=-1;
  } else if (tag==ProcTraverse::BF_TAG) {
    item->unclosed_empty=true;
    set_bf=1;
  } else if (tag==ProcTraverse::XLANG_TAG) { // HACK  for empty xlang
  } else {
    may_ignore_nl=0;
    last_br=NULL;
    empty_line=0;
  }
}

void normalizeBrTool::closeItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item,ProcNodeBufferItem *last)
{
  if (tag==ProcTraverse::BF_TAG) {
    // delete tag entirely
    assert(item==last);
    parent.pop();
    item=NULL;
    parent.ns.pop_back();
    if (empty_line) {
      may_ignore_nl++;
    }
  } else if (tag==ProcTraverse::BLOCK_TAG) {
    last=kill_last_whitespace();
    if (!last_br) {
      last_br=insert_br(last,0,-1); // fake br
    }
    empty_line=0;
    may_ignore_nl=0;
  } else if (tag!=ProcTraverse::BR_TAG) {
    empty_line=0;
    may_ignore_nl=0;
  }
}

void normalizeBrTool::textItem(ProcNodeBufferItem *&item,ProcNodeBufferItem *last)
{
  if (!iswhitespace(item->value,true)) {
    may_ignore_nl=0;
    last_br=NULL;
    empty_line=0;
  }
}

int normalizeBrTool::attribItem(ProcNodeBufferItem *item,const xmlChar *name,const xmlChar *value)
{
  if (item->type==ProcNodeBufferItem::NODE_BR) { // TODO: really handle this (fix ProcTraverse::attrib), for example
    assert(item->unclosed_empty);
    if (get_int_attr(item->no,"no",name,value)) {
      return 1;
    } else if (get_int_attr(item->brk,"break",name,value)) {
      return 1;
    }
    return -1;
  } else if (parent.tag(item->name)==ProcTraverse::BF_TAG) {
    assert(item->unclosed_empty);
    if (get_int_attr(set_bf,"break",name,value)) {
      return 1;
    }
    return -1;
  }
  return 0;
}

void normalizeBrTool::commentItem(ProcNodeBufferItem *&item)
{
  if (empty_line) {
    may_ignore_nl++;
  }
}
// }}}

// {{{ substSpacerTool
substSpacerTool::substSpacerTool(ProcTraverse &parent) : procTool(parent), check_for(NULL) 
{
}

void substSpacerTool::count_spacer(const xmlChar *text,int &no,int &skipchars)
{
  assert(text);
  const xmlChar *tmp=text;
  for (;*tmp;tmp++) {  
    if (!iswhite(*tmp)) {
      break;
    }
  }
  skipchars=tmp-text;
  no=tmp-text+1;
}

void substSpacerTool::openItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item)
{
  check_for=NULL;
  if (tag==ProcTraverse::SPACER_TAG) {
    item->type=ProcNodeBufferItem::NODE_SPACER;
    item->unclosed_empty=true;
  }
}

void substSpacerTool::closeItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item,ProcNodeBufferItem *last)
{
  check_for=NULL;
  if (tag==ProcTraverse::SPACER_TAG) {
    check_for=item;
  }
}

void substSpacerTool::textItem(ProcNodeBufferItem *&item,ProcNodeBufferItem *last)
{
  if (check_for) {
    int no,skipchars;
    count_spacer(item->value,no,skipchars);
    item->set_value(item->value+skipchars);
    check_for->no=no;
    check_for=NULL;
  }
}

int substSpacerTool::attribItem(ProcNodeBufferItem *item,const xmlChar *name,const xmlChar *value)
{
  if (item->type==ProcNodeBufferItem::NODE_SPACER) {
    assert(item->unclosed_empty);
    if (get_int_attr(item->no,"no",name,value)) {
      return 1;
    }
    return -1;
  }
  return 0;
}

void substSpacerTool::commentItem(ProcNodeBufferItem *&item)
{
  check_for=NULL;
}
// }}}

// {{{ substQuoteTool
substQuoteTool::substQuoteTool(ProcTraverse &parent) : procTool(parent)
{
}

void substQuoteTool::openItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item)
{
  if (tag==ProcTraverse::QUOTE_TAG) {
    // trivial heuristic to find matching pairs: no...no|1 -> <>...</>  // TODO? check for consistency
    item->set_name((const xmlChar *)"quote"); // quot -> quote
    item->type=ProcNodeBufferItem::NODE_QUOTE;
    item->unclosed_empty=true;
    item->no=-1;
  }
}

void substQuoteTool::closeItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item,ProcNodeBufferItem *last)
{
  if (tag==ProcTraverse::QUOTE_TAG) {
    assert(item==last);
    item=NULL;
    assert((last)&&(last->is_quote()));
    assert(last->no!=-1);
    if ((last->no&1)==0) { // open
      last->type=ProcNodeBufferItem::NODE_ELEM;
    } else { // close
      if ( (parent.ns.empty())||(!parent.ns.back()) ) {
        parent.tb.error("Quoting weird: got NULL\n");
        return;
      }
      assert(parent.ns.back()->is_quote()); // expected one
      parent.ns.pop_back();
      if (parent.tag(parent.ns.back()->name)==ProcTraverse::QUOTES_TAG) { // matching one
        parent.ns.pop_back();
        last->type=ProcNodeBufferItem::NODE_ELEM_END;
      } else {
        parent.tb.error("Quote numbering is weird: got %s\n",parent.ns.back()->name);
      }
    } 
  }
}

int substQuoteTool::attribItem(ProcNodeBufferItem *item,const xmlChar *name,const xmlChar *value)
{
  if (item->type==ProcNodeBufferItem::NODE_QUOTE) {
    assert(item->unclosed_empty);
    if (get_int_attr(item->no,"no",name,value)) {
      return 1;
    } 
    return -1;
  }
  return 0;
}
// }}}

// {{{ substAkkTool
substAkkTool::substAkkTool(ProcTraverse &parent) : procTool(parent),check_for(NULL) 
{
}

void substAkkTool::openItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item)
{
  check_for=NULL;
}

void substAkkTool::closeItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item,ProcNodeBufferItem *last)
{
  check_for=NULL;
  if (tag==ProcTraverse::AKK_TAG) {
    // akktag is empty (-> no akk-in-akk)
    assert((last)&&(last->is_element_open())&&(strcmp((const char *)last->name,"akk")==0)); // so much for now, more features not yet implemented
    check_for=item;
  }
}

void substAkkTool::textItem(ProcNodeBufferItem *&item,ProcNodeBufferItem *last)
{
  if (check_for) {
    // standard thing: move very next char into <akk></akk> // TODO: fancy stuff
    xmlChar akk[9];
    if (*item->value) {
      int clen=xmlUTF8Size(item->value);
      assert((clen>0)&&(clen<8));
      if ( (!iswhite(*item->value))||(clen>1) ) {
        memcpy(akk,item->value,clen);
        akk[clen]=0;
        ProcNodeBufferItem *txtitem=new ProcNodeBufferItem(NULL,akk);
        txtitem->type=ProcNodeBufferItem::NODE_TEXT;
        parent.move(check_for->prev,txtitem,txtitem);
      }
      item->set_value(item->value+clen);
    }
    check_for=NULL;
  }
}

int substAkkTool::attribItem(ProcNodeBufferItem *item,const xmlChar *name,const xmlChar *value)
{
  if (strcmp((const char *)item->name,"akk")==0) {
    return -1;
  }
  return 0;
}

void substAkkTool::commentItem(ProcNodeBufferItem *&item)
{
  check_for=NULL;
}
// }}}

// {{{ substXlangTool
substXlangTool::substXlangTool(ProcTraverse &parent) : procTool(parent),active(false)
{
}

void substXlangTool::openItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item)
{
  if (tag==ProcTraverse::XLANG_TAG) {
    if (active) {
      parent.tb.error("Double <xlang/> in one line\n"); // TODO?
      return;
    }
    active=true;
  } else if ( (active)&&(tag==ProcTraverse::BR_TAG) ) {
    assert( (parent.ns.back()->type==ProcNodeBufferItem::NODE_ELEM)&&(parent.tag(parent.ns.back()->name)==ProcTraverse::XLANG_TAG) );
    if ( (parent.last)&&(parent.last->is_element_open())&&(parent.tag(parent.last->name)==ProcTraverse::XLANG_TAG) ) { // empty tag
      // TODO:  problem:   normalizeBr will have seen the openItem  and stopped eating whitespace (see HACK in normalizeBrTool::openItem)
      parent.pop();
    } else {
      ProcNodeBufferItem *add=new ProcNodeBufferItem(parent.ns.back()->name);
      add->type=ProcNodeBufferItem::NODE_ELEM_END;
      parent.push(add);
    }
    parent.ns.pop_back();
    active=false;
  }
}

void substXlangTool::closeItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item,ProcNodeBufferItem *last)
{
  if (tag==ProcTraverse::XLANG_TAG) {
    if (!active) {
      parent.tb.error("Bad!\n"); // TODO?
      return;
    }
    delete item; // TODO? save for later?
    item=NULL;
  } else if ( (parent.ns.back()->type==ProcNodeBufferItem::NODE_ELEM)&&(parent.tag(parent.ns.back()->name)==ProcTraverse::XLANG_TAG) ) { // we have to close
    ProcNodeBufferItem *add=new ProcNodeBufferItem(parent.ns.back()->name);
    add->type=ProcNodeBufferItem::NODE_ELEM_END;
    parent.push(add);
    parent.ns.pop_back();
    active=false;
  }
}
// }}}
