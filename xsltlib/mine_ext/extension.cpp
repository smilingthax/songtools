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
#include "chord.h"

class AkkordContainer {
public:
  AkkordContainer() : transpose(0) {}

  void reset(int _transpose) {
    transpose=_transpose;
    data.clear();
    lookup.clear();
    chords.clear();
  }

  void add(int level,int no,const char *str) {
    std::pair<std::map<std::string,int>::iterator,bool> it_b=lookup.insert(std::make_pair(str,chords.size()));
    if (it_b.second) { // not yet known
      chords.push_back(str);
    }

    std::map<std::pair<int,int>,std::pair<int,std::vector<int> > >::iterator it=data.lower_bound(std::make_pair(level,no));
    if ( (it==data.end())||(it->first.first!=level)||(it->first.second!=no) ) {
      it=data.insert(it,std::make_pair(std::make_pair(level,no),std::make_pair(0,std::vector<int>())));
    }
    it->second.second.push_back(it_b.first->second);
  }

  const std::string *get(int level,int no) {
    // for the given level, use the biggest matching entry <= no  - e.g. verse chords are given once, we want to use them for all verses
    std::map<std::pair<int,int>,std::pair<int,std::vector<int> > >::iterator it=--data.upper_bound(std::make_pair(level,no));
    if ( (it==data.end())||(it->first.first!=level) ) {
      return NULL; // nullptr;
    }
    const int pos=it->second.first;
    it->second.first=(pos+1)%it->second.second.size();
    return &chords[it->second.second[pos]];
  }

  bool is_good() const {
    bool ret=true;
    std::map<std::pair<int,int>,std::pair<int,std::vector<int> > >::const_iterator it;
    for (it=data.begin(); it!=data.end(); ++it) {
      if (it->second.first!=0) {
        if (2*it->second.first<(int)it->second.second.size()) { // TODO? better reporting?
          fprintf(stderr,"(%d,%d) %d | too much\n",it->first.first,it->first.second,it->second.first);
        } else {
          fprintf(stderr,"(%d,%d) %d | missing\n",it->first.first,it->first.second,it->second.second.size()-it->second.first);
        }
        ret=false;
//        break;    // more than one error ...
      }
    }
    return ret;
  }

private:
  int transpose;
  std::map<std::pair<int,int>,std::pair<int,std::vector<int> > > data; // (level,pos) -> (curpos,chord_id[])
  std::map<std::string,int> lookup; // orig_string -> chord_id
  std::vector<std::string> chords; // chord_id -> string
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

  const std::string *res=akkCont.get(level,no);
  if (!res) {
    fprintf(stderr,"No chords for (%d,%d)\n",level,no);  // TODO?
    valuePush(ctxt, xmlXPathNewNodeSet(NULL));
  } else {
    valuePush(ctxt, xmlXPathNewString((const xmlChar *)res->c_str()));
  }
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

  // add Akk to AkkCont
  akkCont.add(level,no,(const char *)str);

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

  akkCont.reset(doTranspose);
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
