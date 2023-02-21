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
      try {
        chords.push_back(transpose_chord(str,transpose));
      } catch (std::exception &ex) {
        fprintf(stderr,"%s - in \"%s\"\n",ex.what(),str);
      }
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
          fprintf(stderr,"(%d,%d) %zd | missing\n",it->first.first,it->first.second,it->second.second.size()-it->second.first);
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

// can't use xmlXPathString*Number: we allow a leading '+'
static bool parse_transpose(const xmlChar *str, int &ret)
{
  char *end;
  long int val = strtol((const char *)str, &end, 10);
  if (!*str || *end || val < INT_MIN || val > INT_MAX) {
    return false;
  }
  ret = val;
  return true;
}

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
  float fno = xmlXPathPopNumber(ctxt);
  float flevel = xmlXPathPopNumber(ctxt);
  if (xmlXPathCheckError(ctxt) || isnan(flevel) || isnan(fno)) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"bad level / no\n");
    ctxt->error = XPATH_INVALID_OPERAND;
    return;
  }

  int level = int(floor(flevel + .5));
  int no = int(floor(fno + .5));

  const std::string *res=akkCont.get(level,no);
  if (!res) {
    fprintf(stderr,"No chords for (%d,%d)\n",level,no);  // TODO?
    xmlXPathReturnEmptyNodeSet(ctxt);
  } else {
    valuePush(ctxt, xmlXPathNewCString(res->c_str()));
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
  xmlChar *str = xmlXPathPopString(ctxt);
  float fno = xmlXPathPopNumber(ctxt);
  float flevel = xmlXPathPopNumber(ctxt);
  if (xmlXPathCheckError(ctxt) || isnan(flevel) || isnan(fno) || !str) {
    if (str) {
      xmlFree(str);
    }
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"bad level / no / chord string\n");
    ctxt->error = XPATH_INVALID_OPERAND;
    return;
  }

  int level = int(floor(flevel + .5));
  int no = int(floor(fno + .5));

  // add Akk to AkkCont
  akkCont.add(level,no,(const char *)str);

  xmlFree(str);
  xmlXPathReturnEmptyNodeSet(ctxt);
}

static void functionNotifyAkks(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs==1) {
    xmlChar *stranspose = xmlXPathPopString(ctxt);
    if (xmlXPathCheckError(ctxt) || !stranspose || !parse_transpose(stranspose, doTranspose)) {
      doTranspose=0;
      if (stranspose) {
        xmlFree(stranspose);
      }
      xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"bad transpose\n");
      ctxt->error = XPATH_INVALID_OPERAND;
      return;
    }
    xmlFree(stranspose);
  } else if (nargs==0) {
    doTranspose=0;
  } else {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need 0 or 1 arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }

  akkCont.reset(doTranspose);
  xmlXPathReturnEmptyNodeSet(ctxt);
}

static void functionCheckAkks(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=0) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need 0 arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }
  xmlXPathReturnBoolean(ctxt,(int)akkCont.is_good());
}

static void functionTranspose(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=2) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need two arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }

  // Argumente holen
  xmlChar *stranspose = xmlXPathPopString(ctxt);
  xmlChar *str = xmlXPathPopString(ctxt);
  int transpose;
  if (xmlXPathCheckError(ctxt) || !str || !stranspose || !parse_transpose(stranspose, transpose)) {
    if (str) {
      xmlFree(str);
    }
    if (stranspose) {
      xmlFree(stranspose);
    }
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"bad chord string / transpose\n");
    ctxt->error = XPATH_INVALID_OPERAND;
    return;
  }
  xmlFree(stranspose);

  try {
    std::string res = transpose_chord((const char *)str,transpose);
    xmlFree(str);
    valuePush(ctxt, xmlXPathNewCString(res.c_str()));

  } catch (std::exception &ex) {
    fprintf(stderr,"%s - in \"%s\"\n",ex.what(),(const char *)str);
    // TODO...?
    xmlFree(str);

    xmlXPathReturnEmptyNodeSet(ctxt);
  }
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
