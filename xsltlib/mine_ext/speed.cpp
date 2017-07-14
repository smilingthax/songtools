/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include "extension.h"
#include <math.h>
#include <string.h>
#include <libxml/xpathInternals.h>
#include <libxslt/xslt.h>
//#include <libxslt/xsltInternals.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>

// Speed up functions
extern "C" {
  static void functionSubstKill(xmlXPathParserContextPtr ctxt, int nargs);
  static void functionSubstAkkTex(xmlXPathParserContextPtr ctxt, int nargs);
  static void functionHlpNLtxt(xmlXPathParserContextPtr ctxt, int nargs);
  static void functionRepIt(xmlXPathParserContextPtr ctxt, int nargs);
}

static void functionSubstKill(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=1) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need one argument\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }
  // Argumente holen
  xmlXPathObjectPtr obj1 = valuePop(ctxt);
  xmlChar *str=xmlXPathCastToString(obj1);

  // transform
  int iA,iB=0;
  static int mlen=0;  // TODO: garbage collector!
  static char *out=NULL;
  if (mlen==0) {
    mlen=1000;
    out=(char *)malloc(mlen);
    if (!out) {
      mlen=0;
      xmlXPathFreeObject(obj1);
      xmlFree(str);
      return;
    }
  }
  for (iA=0;str[iA];iA++) {
    if (str[iA]=='_') {
      out[iB++]='\\';
      out[iB++]='_';
    } else if (str[iA]==10) { // TODO? only first occurence??
      for (;str[iA+1];iA++) {
        if (str[iA+1]!=' ') {
          break;
        }
      }
    } else {
      out[iB++]=str[iA];
    }
    if (iB+2<=mlen) {
      mlen+=1000;
      out=(char *)realloc(out,mlen);
      if (!out) {
        mlen=0;
        xmlXPathFreeObject(obj1);
        xmlFree(str);
        return;
      }
    }
  }
  out[iB]=0;

  xmlXPathFreeObject(obj1);
  xmlFree(str);
  valuePush(ctxt, xmlXPathNewString((xmlChar *)out));
//  free(out);
}

static void functionSubstAkkTex(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=2) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need two arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }
  // Argumente holen
  xmlXPathObjectPtr obj2 = valuePop(ctxt);
  xmlXPathObjectPtr obj1 = valuePop(ctxt);
  xmlChar *note=xmlXPathCastToString(obj1);
  xmlChar *txt=xmlXPathCastToString(obj2);

  int iA,iB=0;
  char *out=(char *)malloc(xmlStrlen(note)+xmlStrlen(txt)+15);
  if (!out) {
    xmlXPathFreeObject(obj1);
    xmlXPathFreeObject(obj2);
    xmlFree(txt);
    xmlFree(note);
    return;
  }
  if (!*txt) {
    strcpy(out,"\\akks{");iB=6;
  } else if ( (*txt=='_')&&(txt[1]==0) ) {
    strcpy(out,"\\akkt{");iB=6;
  } else {
    strcpy(out,"\\akk{");iB=5;
  }
  for (iA=0;note[iA];iA++) {
    if (note[iA]=='#') {
      out[iB++]='\\';
      out[iB++]='#';
    } else {
      out[iB++]=note[iA];
    }
  }
  if (!*txt) {
    strcpy(out+iB,"}{ }");iB+=4;
  } else if ( (*txt=='_')&&(txt[1]==0) ) {
    out[iB++]='}';
  } else {
    out[iB++]='}';
    for (iA=0;txt[iA];iA++) {
      if (txt[iA]=='_') {
        out[iB++]='\\';
        out[iB++]='_';
      } else {
        out[iB++]=txt[iA];
      }
    }
  }
  out[iB]=0;

  xmlXPathFreeObject(obj1);
  xmlXPathFreeObject(obj2);
  xmlFree(txt);
  xmlFree(note);
  valuePush(ctxt, xmlXPathNewString((xmlChar *)out));
  free(out);
}

static void functionHlpNLtxt(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=1) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need one argument\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }
  // Argumente holen
  xmlXPathObjectPtr obj1 = valuePop(ctxt);
  xmlChar *str=xmlXPathCastToString(obj1);

  // transform (in-place)
  int iA,iB=0;
  for (iA=0;str[iA];iA++) {
    if (str[iA]==10) {
      for (;str[iA+1];iA++) {
        if ( (str[iA+1]!=' ')&&(str[iA+1]!='\t') ) {
          break;
        }
      }
    } else {
      str[iB++]=str[iA];
    }
  }
  str[iB]=0;

  xmlXPathFreeObject(obj1);
  valuePush(ctxt, xmlXPathNewString(str));
  xmlFree(str);
}

static void functionRepIt(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=2) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need two arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }
  // Argumente holen
  xmlXPathObjectPtr obj2 = valuePop(ctxt);
  xmlXPathObjectPtr obj1 = valuePop(ctxt);
  xmlNodeSetPtr nodelist=obj1->nodesetval;
  int no = int(floor(xmlXPathCastToNumber(obj2) + .5));
  if (no<0) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"number must be positive\n");
    ctxt->error = XPATH_INVALID_OPERAND;
    return;
  } else if (no==0) {
    xmlXPathFreeObject(obj1);
    xmlXPathFreeObject(obj2);
    valuePush(ctxt, xmlXPathNewNodeSet(NULL));
    return;
  }

  if (xmlXPathNodeSetIsEmpty(nodelist)) {
    xmlXPathFreeObject(obj2);
    if ( (obj1->type==XPATH_STRING)&&(obj1->stringval)&&(*obj1->stringval) ) {
      int len=strlen((char *)obj1->stringval);
      char *ret=(char *)malloc(len*no+2),*tmp;
      for (tmp=ret;no>0;no--) {
        strcpy(tmp,(char *)obj1->stringval);
        tmp+=len;
      }
      xmlXPathFreeObject(obj1);
      valuePush(ctxt, xmlXPathNewString((xmlChar *)ret));
      free(ret);
      return;
    }
    valuePush(ctxt, obj1);
    return;
  }

  xsltTransformContextPtr tctxt;
  tctxt=xsltXPathGetTransformContext(ctxt);
  if (tctxt == NULL) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
        "RepIt : internal error tctxt == NULL\n");
    return;
  }

  int iA;
  xmlXPathObjectPtr ret = NULL;
  xmlDocPtr container;
  xmlNodePtr node;
  container = xsltCreateRVT(tctxt);
  if (container != NULL) {
    xsltRegisterTmpRVT(tctxt, container);
    ret = xmlXPathNewNodeSet(NULL);
    if (ret != NULL) {
      ret->boolval = 0; /* Freeing is not handled there anymore */
      for (;no>0;no--) {
        for (iA=0;iA<nodelist->nodeNr;iA++) {
          node=xmlCopyNode(nodelist->nodeTab[iA],1);
          if (xmlAddChild((xmlNodePtr) container, node)==node) { // not merged
            xmlXPathNodeSetAdd(ret->nodesetval, node);
          }
        }
      }
    }
  }

  xmlXPathFreeObject(obj1);
  xmlXPathFreeObject(obj2);
  if (ret) {
    valuePush(ctxt, ret);
  }
}

void *initSpeedExt(xsltTransformContextPtr ctxt, const xmlChar *URI)
{
  xsltRegisterExtFunction(ctxt,(xmlChar *)"subst_ul-kill_nl",URI,functionSubstKill);// tex
  xsltRegisterExtFunction(ctxt,(xmlChar *)"akk_subst_tex",URI,functionSubstAkkTex); // tex
  xsltRegisterExtFunction(ctxt,(xmlChar *)"nl_hlp",URI,functionHlpNLtxt);           // puretext
  xsltRegisterExtFunction(ctxt,(xmlChar *)"rep_it",URI,functionRepIt);              // general
  return NULL;
}
