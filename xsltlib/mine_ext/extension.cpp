/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include "extension.h"
#include <vector>
#include <map>
#include <math.h>
#include <libxml/xmlmemory.h>
#include <libxml/xmlIO.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxslt/xslt.h>
#include <libxslt/xsltInternals.h>
#include <libxslt/transform.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include <libexslt/exslt.h>
#include "textItem.h"
#include "chord.h"

using namespace std;

class AkkordQueue {
public:
  AkkordQueue() : curpos(0) {}
  virtual ~AkkordQueue() {
    for(vector<AkkordItem *>::iterator it=akkVec.begin(); it!=akkVec.end(); it++) {
      delete (*it);
    }
  }
  void append(AkkordItem *akkIt) {
    assert(akkIt);
    assert(!curpos);
    akkVec.push_back(akkIt);
  }
  const AkkordItem& operator[](unsigned int pos) const {
assert(false);
    assert(akkVec.size());
    pos%=akkVec.size();
    assert(akkVec[pos]);
    return *(akkVec[pos]);
  }
  const AkkordItem &get_next() {
    int pos=curpos;
    curpos=(curpos+1)%akkVec.size();
    assert(akkVec[pos]);
    return *(akkVec[pos]);
  }
  bool is_good() {
    return (curpos==0);
  }

  int curpos;
private:
  vector<AkkordItem *> akkVec;
};

class AkkordContainer {
public:
  virtual ~AkkordContainer() {
    for(map<int,AkkordQueue *>::iterator it=akkMap.begin(); it!=akkMap.end(); it++) {
      delete (it->second);
    }
  }
  void reset() {
    for(map<int,AkkordQueue *>::iterator it=akkMap.begin(); it!=akkMap.end(); it++) {
      delete (it->second);
    }
    akkMap.clear();
    assert(!akkMap.size());
  }
  void append(int no,AkkordQueue *akkQu) {
    assert(akkQu);
    assert(!akkMap.count(no));
    akkMap[no]=akkQu;
  }
  AkkordQueue& pos(int no) { // nur get
    assert(akkMap.size());
    if (akkMap.count(no)) {
      assert(akkMap[no]);
      return *(akkMap[no]);
    }
    map<int,AkkordQueue *>::iterator it=--(akkMap.upper_bound(no));
//    assert((it!=akkMap.begin())&&(it->first>=(no&0xff00)));
//    assert(it!=akkMap.begin()); // häh?
    if (it->first<(no&0xff00)) {
      assert(akkMap.count(0));
      assert(akkMap[0]);
      return *(akkMap[0]);
    }
    assert(it->second);
    return *(it->second);
  }
  AkkordQueue& operator[](int no) { // get and create
    if (!akkMap.count(no)) {
      akkMap[no]=new AkkordQueue();
    }
    assert(akkMap[no]);
    return *(akkMap[no]);
  }
  bool is_good() {
    for(map<int,AkkordQueue *>::iterator it=akkMap.begin(); it!=akkMap.end(); it++) {
      if (!it->second->is_good()) {
fprintf(stderr,"(%d,%d) %d\n",(it->first>>8),(it->first)&0xff,it->second->curpos);
        return false;
      }
    }
    return true;
  }

private:
  map<int,AkkordQueue *> akkMap;
};

AkkordContainer akkCont;
int doTranspose=0;


extern "C" {
  static void functionAkkify(xmlXPathParserContextPtr ctxt, int nargs);
  static void functionGrabAkk(xmlXPathParserContextPtr ctxt, int nargs);
  static void functionNotifyAkks(xmlXPathParserContextPtr ctxt, int nargs);
  static void functionCheckAkks(xmlXPathParserContextPtr ctxt, int nargs);
}

static void functionAkkify(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=2) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need two arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }
  // Argumente holen
  xmlXPathObjectPtr obj2 = valuePop(ctxt);
  xmlXPathObjectPtr obj1 = valuePop(ctxt);
  int level = int(floor(xmlXPathCastToNumber(obj1) + .5));
  int no = int(floor(xmlXPathCastToNumber(obj2) + .5));

  xmlXPathFreeObject(obj1);
  xmlXPathFreeObject(obj2);

  assert((level>=0)&&(level<=0xff)&&(no>=0)&&(no<=0xff));
  valuePush(ctxt, xmlXPathNewString((xmlChar *)akkCont.pos(level*0x100+no).get_next().get_text()));
}

static void functionGrabAkk(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=3) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need three arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }
  // Argumente holen
  xmlXPathObjectPtr obj3 = valuePop(ctxt);
  xmlXPathObjectPtr obj2 = valuePop(ctxt);
  xmlXPathObjectPtr obj1 = valuePop(ctxt);
  int level = int(floor(xmlXPathCastToNumber(obj1) + .5));
  int no = int(floor(xmlXPathCastToNumber(obj2) + .5));
  xmlChar *str=xmlXPathCastToString(obj3);

  assert((level>=0)&&(level<=0xff)&&(no>=0)&&(no<=0xff));
  AkkordItem *aki=new AkkordItem();
  aki->set_text((char *)str);
  akkCont[level*0x100+no].append(aki);

  xmlXPathFreeObject(obj1);
  xmlXPathFreeObject(obj2);
  xmlXPathFreeObject(obj3);
  xmlFree(str);
  valuePush(ctxt, xmlXPathNewNodeSet(NULL));
}

static void functionNotifyAkks(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs==1) {
    xmlXPathObjectPtr obj1 = valuePop(ctxt);
    doTranspose=int(floor(xmlXPathCastToNumber(obj1) + .5));
    xmlXPathFreeObject(obj1);
  } else if (nargs==0) {
    doTranspose=0;
  } else {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need 0 or 1 arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }
  akkCont.reset();
  valuePush(ctxt, xmlXPathNewNodeSet(NULL));
}

static void functionCheckAkks(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=0) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need 0 arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }
  valuePush(ctxt, xmlXPathNewBoolean((int)akkCont.is_good()));
}

static void functionTranspose(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=2) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need two arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }

  xmlXPathObjectPtr obj2 = valuePop(ctxt);
  int transpose=int(floor(xmlXPathCastToNumber(obj2) + .5));
  xmlXPathFreeObject(obj2);

  xmlXPathObjectPtr obj1 = valuePop(ctxt);
  xmlChar *str=xmlXPathCastToString(obj1);
  xmlXPathFreeObject(obj1);

  try {
    std::string res = transpose_chord((const char *)str,transpose);
    xmlFree(str);
    valuePush(ctxt, xmlXPathNewString((const xmlChar *)res.c_str()));
    return;
  } catch (std::exception &ex) {
fprintf(stderr,"%s - in \"%s\"\n",ex.what(),(const char *)str);
    // TODO...?
  }
  xmlFree(str);

  valuePush(ctxt, xmlXPathNewNodeSet(NULL));
}

void *initMineExt(xsltTransformContextPtr ctxt, const xmlChar *URI)
{
  xsltRegisterExtFunction(ctxt,(xmlChar *)"getAkk",URI,functionAkkify);
  xsltRegisterExtFunction(ctxt,(xmlChar *)"grabAkk",URI,functionGrabAkk);
  xsltRegisterExtFunction(ctxt,(xmlChar *)"noteAkks",URI,functionNotifyAkks);
  xsltRegisterExtFunction(ctxt,(xmlChar *)"checkAkks",URI,functionCheckAkks);

  xsltRegisterExtFunction(ctxt,(xmlChar *)"transpose",URI,functionTranspose);
  return NULL;
}

int load_mine_ext()
{
  xsltRegisterExtModule((xmlChar *)"thax.home/mine-ext",initMineExt,NULL);
  xsltRegisterExtModule((xmlChar *)"thax.home/mine-ext-speed",initSpeedExt,NULL);
  return 1;
}

#ifdef STANDALONE
extern "C" {
int thax_home_mine_ext_init();
int thax_home_mine_ext_speed_init();
};
int thax_home_mine_ext_init()
{
  return load_mine_ext();
}
int thax_home_mine_ext_speed_init()
{
  return load_mine_ext();
}
#endif
