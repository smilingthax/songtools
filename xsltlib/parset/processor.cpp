/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include <assert.h>
#include <stdexcept>
#include <string.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
//#include <libxslt/xslt.h>
//#include <libxslt/xsltInternals.h>
//#include <libxslt/transform.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include "processor.h"
#include "ptools.h"

#include <stdio.h>

using namespace std;

// {{{ TreeBuilder
TreeBuilder::TreeBuilder(xmlDocPtr doc,xmlXPathObjectPtr nodeset,xmlChar *_debug,xmlXPathParserContextPtr ctxt)
                      : doc(doc),nodeset(nodeset),ctxt(ctxt)
{
  assert(doc);
  node=(xmlNodePtr) doc;
  if (_debug) {
    debug=(xmlChar *)strdup((const char *)_debug);
  } else {
    debug=NULL;
  }
  err=false;
}

TreeBuilder::~TreeBuilder()
{
  free(debug);
}

void TreeBuilder::openNode(const xmlChar *name)
{
  if (err) {
    return;
  }
  xmlNodePtr new_node = xmlNewDocRawNode(doc, NULL, name,NULL);
  xmlAddChild(node, new_node);
  if ( (nodeset)&&(node==(xmlNodePtr)doc) ) {
    xmlXPathNodeSetAddUnique(nodeset->nodesetval, new_node);
  }
  node=new_node;
}

void TreeBuilder::closeNode(const xmlChar *name)
{
  if (err) {
    return;
  }
  assert((node)&&(node!=(xmlNodePtr)doc));
  if (strcmp((const char *)node->name,(const char *)name)!=0) {
    error("Closing wrong node (%s, expected %s)",node->name,name);
  }
  node=node->parent;
}

void TreeBuilder::text(const xmlChar *text)
{
  if (err) {
    return;
  }
  assert(node);
  xmlNodePtr new_node = xmlNewDocText(doc,text);
  if ( (xmlAddChild(node, new_node)==new_node)&&(nodeset)&&(node==(xmlNodePtr)doc) ) { // not merged
    xmlXPathNodeSetAddUnique(nodeset->nodesetval, new_node);
  }
}

void TreeBuilder::attrib(const xmlChar *name,const xmlChar *value)
{
  if (err) {
    return;
  }
  assert(node);
  xmlNewProp(node,name,value);
}

void TreeBuilder::attrib(const xmlChar *name,int value)
{
  char tmp[50];
  snprintf(tmp,49,"%d",value);
  attrib(name,(xmlChar *)tmp);
}

void TreeBuilder::comment(const xmlChar *text)
{
  if (err) {
    return;
  }
  assert(node);
  xmlNodePtr new_node = xmlNewDocComment(doc,text);
  xmlAddChild(node, new_node);
  if ( (nodeset)&&(node==(xmlNodePtr)doc) ) {
    xmlXPathNodeSetAddUnique(nodeset->nodesetval, new_node);
  }
}

void TreeBuilder::error(const char *fmt,...)
{
  va_list va;

  err=true;
  if (ctxt) {
    char *str,*tmp;
    int len=150,need;
    str=(char *)malloc(len);
    if (!str) {
      return;
    }
    while (1) {
      va_start(va,fmt);
      need=vsnprintf(str,len,fmt,va);
      va_end(va);
      if (need==-1) {
        len+=100;
      } else if (need>=len) {
        len=need;
      } else {
        break;
      }
      tmp=(char *)realloc(str,len);
      if (!tmp) {
        free(str);
        return;
      }
      str=tmp;
    }
    if (debug) {
      xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL, "%s: %s",(const char *)debug,str);
    } else {
      xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL, "%s",str);
    }
    free(str);
  } else {
    va_start(va,fmt);
    if (debug) {
      printf("%s: ",(const char *)debug);
    }
    vprintf(fmt,va);
    va_end(va);
  }
}

bool TreeBuilder::has_error()
{
  return err;
}
// }}}

// {{{ ProcNodeBufferItem
ProcNodeBufferItem::ProcNodeBufferItem()
{
  name=value=NULL;
  type=NODE_NONE;
  prev=next=NULL;
  attrqueue=attrlast=NULL;
  no=-1;
  brk=-1;
  unclosed_empty=false;
}

ProcNodeBufferItem::ProcNodeBufferItem(const xmlChar *_name,const xmlChar *_value)
{
  if (_name) {
    name=(xmlChar *)strdup((char *)_name);
    if (!name) {
      throw bad_alloc();
    }
  } else {
    name=NULL;
  }
  if (_value) {
    value=(xmlChar *)strdup((char *)_value);
    if (!value) {
      free(name);
      throw bad_alloc();
    }
  } else {
    value=NULL;
  }
  type=NODE_NONE;
  prev=next=NULL;
  attrqueue=attrlast=NULL;
  no=-1;
  brk=-1;
  unclosed_empty=false;
}

ProcNodeBufferItem::~ProcNodeBufferItem()
{
  free(name);
  free(value);
}

void ProcNodeBufferItem::set_name(const xmlChar *_name)
{
  free(name);
  if (_name) {
    name=(xmlChar *)strdup((char *)_name);
    if (!name) {
      throw bad_alloc();
    }
  } else {
    name=NULL;
  }
}

void ProcNodeBufferItem::set_value(const xmlChar *_value)
{
  xmlChar *tmp=value;
  if (_value) {
    value=(xmlChar *)strdup((char *)_value);
    if (!value) {
      free(tmp);
      throw bad_alloc();
    }
  } else {
    value=NULL;
  }
  free(tmp); // free afterwards! _value may depend on old value!
}

bool ProcNodeBufferItem::is_element() const
{
  return (type==NODE_ELEM)||(type==NODE_ELEM_END)||(type==NODE_BR)||(type==NODE_SPACER)||(type==NODE_AKK);
}

bool ProcNodeBufferItem::is_element_open() const
{
  return (type==NODE_ELEM);
}

bool ProcNodeBufferItem::is_element_close() const
{
  return (type==NODE_ELEM_END);
}

bool ProcNodeBufferItem::is_text() const
{  // a comment is also an empty text (!)
  return (type==NODE_TEXT);
}

bool ProcNodeBufferItem::is_attrib() const
{
  return (type==NODE_ATTRIB);
}

bool ProcNodeBufferItem::is_comment() const
{ // comment is a text with no value but with a name
  return (type==NODE_TEXT)&&(!value)&&(name);
}

bool ProcNodeBufferItem::is_br() const
{
  return (type==NODE_BR);
}

bool ProcNodeBufferItem::is_spacer() const
{
  return (type==NODE_SPACER);
}

bool ProcNodeBufferItem::is_akk() const
{
  return (type==NODE_AKK);
}

bool ProcNodeBufferItem::is_whitespace(bool nl_as_WS) const
{
  if (type==NODE_TEXT) {
    if (!value) { // comment
      return true;
    }
    return iswhitespace(value,nl_as_WS);
  }

  return false;
}

void ProcNodeBufferItem::build(TreeBuilder &tb) const
{
  int val;
// TODO? check unclosed_empty?
  ProcNodeBufferItem *item;
  switch (type) {
  case NODE_ELEM:
    tb.openNode(name);
    // generate attribs
    for (item=attrqueue;item;item=item->next) {
      item->build(tb);
    }
    break;
  case NODE_ELEM_END:
    tb.closeNode(name);
    break;
  case NODE_TEXT:
    if (name) { // oh, a comment!
      tb.comment(name);
    } else {
      tb.text(value);
    }
    break;
  case NODE_ATTRIB:
    tb.attrib(name,value);
    break;
  case NODE_BR:
    if (!no) {
      break;
    }
    tb.openNode(name);
    val=(no!=-1)?no:1;
    tb.attrib((const xmlChar *)"no",val);
    if (brk==-1) {
      if (val>1) {
        tb.attrib((const xmlChar *)"break",1);
      } else {
        tb.attrib((const xmlChar *)"break",0);
      }
    } else {
      tb.attrib((const xmlChar *)"break",brk);
    }
    tb.closeNode(name);
    break;
  case NODE_SPACER:
    tb.openNode(name);
    val=(no!=-1)?no:1;
    tb.attrib((const xmlChar *)"no",val);
    tb.closeNode(name);
    break;
  case NODE_AKK:
    tb.openNode(name);
    if (value) {
      tb.text(value);
    }
    tb.closeNode(name);
    break;
  case NODE_NONE:
    tb.error("Unexpected NODE_NONE\n");
    break;
  }
}
// }}}

// {{{ ProcTraverse
bool ProcTraverse::in_list(ProcNodeBufferItem *item,ProcNodeBufferItem *start,ProcNodeBufferItem *end) const // {{{
{
  if (!item) {
    return false;
  } else if (item==end) { // speedup
    return true;
  }
  if ( (!start)&&(end) ) { // reverse search
    while (end) {
      if (end==item) {
        return true;
      }
      end=end->prev;
    }
    return false;
  }
  while (start) {
    if (start==item) {
      return true;
    }
    if (start==end) {
      return false;
    }
    start=start->next;
  }
  return false;
}
// }}}

void ProcTraverse::move(ProcNodeBufferItem *after,ProcNodeBufferItem *start,ProcNodeBufferItem *end) // {{{
{
  assert(!in_list(after,start,end));
  assert((!after)||(in_list(after,queue,last)));
  ProcNodeBufferItem *save;
  if ( (!start)&&(!end) ) {
    return;
  } else if ( (!start)&&(end) ) {
    // start=queue; NO! -> do not assume that [start;end] is part of [queue;last]!
    save=end;
    while (save) { // executes at least once!
      start=save;
      save=save->prev;
    }
    assert(start); // should always succeed
  } else if (!end) {
    save=start;
    while (save) { // executes at least once!
      end=save;
      save=save->next;
    }
    assert(end); // should always succeed
  }
  // unlink chunk
  if (start->prev) {
    start->prev->next=end->next;
  } else if (start==queue) {
    queue=end->next;
  }
  if (end->next) {
    end->next->prev=start->prev;
  } else if (end==last) {
    last=start->prev;
  }
  // relink chunk
  start->prev=after;
  if (!after) {
    end->next=queue;
  } else {
    end->next=after->next;
  }
  if (start->prev) {
    start->prev->next=start;
  } else {
    queue=start;
  }
  if (end->next) {
    end->next->prev=end;
  } else {
    last=end;
  }
}
// }}}

void ProcTraverse::push(ProcNodeBufferItem *item) // {{{
{
  assert(item);
  assert(!in_list(item,queue,last));
  // link it in
  item->prev=last;
  item->next=NULL;
  if (last) {
    last->next=item;
  } else {
    queue=item;
  }
  last=item;
}
// }}}

void ProcTraverse::pop() // {{{
{
  if (!last) {
    assert(false);
    return;
  }
  ProcNodeBufferItem *save=last;
  last=last->prev;
  if (last) {
    last->next=NULL;
  } else {
    assert(save==queue);
    queue=NULL;
  }
  delete save;
}
// }}}

static void extra_br(TreeBuilder &tb) // {{{
{
  ProcNodeBufferItem br((const xmlChar *)"br");
  br.type=ProcNodeBufferItem::NODE_BR;
  br.build(tb);
}
// }}}

void ProcTraverse::flush() // {{{
{
  if (tb.has_error()) {
    return;
  }
  ProcNodeBufferItem *save;
  // state machine to encapsulate everything not in a block tag into <base></base>
  enum { Yes, Doing, No } base=Yes;
  bool hasBr=true; // (value only used when base==Doing)
  while (queue) {
    if ( (queue->is_element_open())&&(is_blocktag(queue->name)) ) {
      if (base==Doing) {
        if (!hasBr) {
          extra_br(tb);
        }
        tb.closeNode((const xmlChar*)"base");
      }
      base=No;
    } else if ( (queue->is_element_close())&&(is_blocktag(queue->name)) ) {
      base=Yes;
    } else if ( (base==Yes)&&(!queue->is_whitespace(true)) ) {
      tb.openNode((const xmlChar*)"base");
      base=Doing;
    }
    queue->build(tb);
    if (base==Doing) {
      if (queue->is_br()) {
        if (queue->no>1) {
          tb.closeNode((const xmlChar*)"base");
          base=Yes;
        } else {
          hasBr=true;
        }
      } else if (!queue->is_whitespace(true)) {
        hasBr=false;
      }
    }
    save=queue;
    queue=queue->next;
    delete save;
  }
  if (base==Doing) {
    if (!hasBr) {
      extra_br(tb);
    }
    tb.closeNode((const xmlChar*)"base");
  }
  last=NULL;
}
// }}}

#if 0  // not used
ProcNodeBufferItem *ProcTraverse::operator[](int index) // {{{
{
  ProcNodeBufferItem *ret;
  if (index>=0) {
    ret=queue;
    while ( (ret)&&(index>0) ) {
      ret=ret->next;
      index--;
    }
  } else {
    ret=last;
    while ( (ret)&&(index<-1) ) {
      ret=ret->prev;
      index++;
    }
  }
  // if index>0 resp. index<-1 => ret=NULL
  return ret;
}
// }}}
#endif

ProcTraverse::ProcTraverse(TreeBuilder &tb) : tb(tb)
{
  queue=last=NULL;  // queue empty (queue=last) -> <content> is directly preceding

  tools.push_back(new substXlangTool(*this));
  tools.push_back(new normalizeBrTool(*this));
  tools.push_back(new substSpacerTool(*this));
  tools.push_back(new substAkkTool(*this));
}

ProcTraverse::~ProcTraverse()
{
  if (ns.size()) {
    tb.error("Strange problem\n");
  }

  flush();
  // only not flushed items (e.g. tb.has_error())
  ProcNodeBufferItem *item;
  while (queue) {
    item=queue;
    queue=queue->next;
    delete item;
  }

  const int len=tools.size();
  for (int iA=0;iA<len;iA++) {
    delete tools[iA];
  }
  tools.clear();
}

bool ProcTraverse::is_blocktag(const xmlChar *name)
{
  const char *nam=(const char *)name;
  if (strcmp(nam,"bridge")==0) {
    return true;
  } else if (strcmp(nam,"vers")==0) {
    return true;
  } else if (strcmp(nam,"refr")==0) {
    return true;
  } else if (strcmp(nam,"ending")==0) {
    return true;
  } else if (strcmp(nam,"base")==0) { // -> allow them in input? (TODO?)
    return true;
/*  } else if (strcmp(nam,"showrefr")==0) {
    return true;*/ // TODO: should not happen
  } else if (strcmp(nam,"img")==0) {
    return true;
  }
  return false;
}

ProcTraverse::Tagname ProcTraverse::tag(const xmlChar *name)
{
  const char *nam=(const char *)name;
  if (is_blocktag(name)) {
    return BLOCK_TAG;
  } else if (strcmp(nam,"br")==0) {
    return BR_TAG;
  } else if (strcmp(nam,"bf")==0) {
    return BF_TAG;
  } else if (strcmp(nam,"spacer")==0) {
    return SPACER_TAG;
  } else if (strcmp(nam,"akk")==0) {
    return AKK_TAG;
  } else if (strcmp(nam,"xlang")==0) {
    return XLANG_TAG;
  }
  return UNKNOWN_TAG;
}

void ProcTraverse::openNode(const xmlChar *name)
{
  ProcNodeBufferItem *item=NULL;

  if ( (last)&&(last->unclosed_empty) ) {
    tb.error("<%s> tag must be empty (no subnode)\n",name);
    return;
  }
  item=new ProcNodeBufferItem(name);
  item->type=ProcNodeBufferItem::NODE_ELEM;

  Tagname tn=tag(name);
  const int len=tools.size();
  for (int iA=0;iA<len;iA++) {
    tools[iA]->openItem(tn,item);
    if (!item) {
      break;
    }
  }
  if (item) {
    // link it in
    push(item);
    ns.push_back(item);
  } else {
    ns.push_back(NULL);
  }
}

void ProcTraverse::closeNode(const xmlChar *name)
{
  ProcNodeBufferItem *item=NULL;

  if (!ns.back()) { // skipped
    ns.pop_back();
    return;
  }

  if ( (last)&&(last->unclosed_empty) ) {
    last->unclosed_empty=false;
    item=last;
  } else {
    item=new ProcNodeBufferItem(name);
    item->type=ProcNodeBufferItem::NODE_ELEM_END;
  }

  Tagname tn=tag(name);
  const int len=tools.size();
  for (int iA=0;iA<len;iA++) {
    tools[iA]->closeItem(tn,item,last);
    if (!item) {
      return;
    }
  }

  if (item!=last) {
    // link it in
    push(item);
  }
  ns.pop_back();
}

void ProcTraverse::text(const xmlChar *text)
{
  ProcNodeBufferItem *item;
  if ( (last)&&(last->unclosed_empty) ) {
    tb.error("<%s> tag must be empty (no text!)\n",last->name);
    return;
  }
  if (!*text) {
    return;
  }
  item=new ProcNodeBufferItem(NULL,text);
  item->type=ProcNodeBufferItem::NODE_TEXT;
  const int len=tools.size();
  for (int iA=0;iA<len;iA++) {
    tools[iA]->textItem(item,last);
    if (!item) {
      return;
    }
  }
  // link it in
  push(item);
}

void ProcTraverse::attrib(const xmlChar *name,const xmlChar *value)
{
  assert(  (last)&&( (last->is_element_open())||(last->unclosed_empty) )  );

  const int len=tools.size();
  for (int iA=0;iA<len;iA++) {
    int ret=tools[iA]->attribItem(last,name,value);
    if (ret<0) {
      tb.error("Invalid Attribute for <%s>-tag: %s\n",last->name,name);
      return;
    } else if (ret) { // ok, consumed
      return;
    }
  }
  ProcNodeBufferItem *item;
  item=new ProcNodeBufferItem(name,value);
  item->type=ProcNodeBufferItem::NODE_ATTRIB;
  // link it into attrib-list
  item->prev=last->attrlast;
  item->next=NULL;
  if (last->attrlast) {
    last->attrlast->next=item;
  } else {
    last->attrqueue=item;
  }
  last->attrlast=item;
}

void ProcTraverse::comment(const xmlChar *text)
{
  ProcNodeBufferItem *item;

  item=new ProcNodeBufferItem(text,NULL);  // comment is a text with no value, but with a name
  item->type=ProcNodeBufferItem::NODE_TEXT;

  const int len=tools.size();
  for (int iA=0;iA<len;iA++) {
    tools[iA]->commentItem(item);
    if (!item) {
      return;
    }
  }
  if (*text) {
    // link it in
    push(item);
  } else {
    delete item;
  }
}
// }}}

// {{{ bool iswhitespace(str,nl_as_WS)
// speeded up version
bool iswhitespace(const xmlChar *str,bool nl_as_WS)
{
  if (nl_as_WS) {
    for (;*str;str++) {
      if (!iswhitenl(*str)) {
        return false;
      }
    }
  } else {
    for (;*str;str++) {
      if (!iswhite(*str)) {
        return false;
      }
    }
  }
  return true;
}
// }}}

// {{{ bool get_int_attr(&to,*attrname,*name,*value)  - if name==attrname get value
bool get_int_attr(int &to,const char *attrname,const xmlChar *name,const xmlChar *value)
{
  char *tmp;
  assert((name)&&(attrname));
  if ( (value)&&(strcmp((const char *)name,attrname)==0) ) {
    to=strtol((const char *)value,&tmp,10);
    return (*tmp==0);
  }
  return false;
}
// }}}
