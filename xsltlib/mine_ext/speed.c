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

static void functionSubstKill(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=1) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need one argument\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }

  // Argumente holen
  xmlChar *str = xmlXPathPopString(ctxt);
  if (!str) {
    return;
  }

  // transform
  int iA,iB=0;
  static int mlen=0;  // TODO: garbage collector!
  static char *out=NULL;
  if (mlen==0) {
    mlen=1000;
    out=(char *)malloc(mlen);
    if (!out) {
      mlen=0;
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
        xmlFree(str);
        return;
      }
    }
  }
  out[iB]=0;

  xmlFree(str);
  valuePush(ctxt, xmlXPathNewCString(out));
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
  xmlChar *txt = xmlXPathPopString(ctxt);
  if (!txt) {
    return;
  }
  xmlChar *note = xmlXPathPopString(ctxt);
  if (!note) {
    xmlFree(txt);
    return;
  }

  int iA,iB=0;
  xmlChar *out=xmlMalloc(xmlStrlen(note)+xmlStrlen(txt)+15);
  if (!out) {
    xmlFree(txt);
    xmlFree(note);
    return;
  }
  if (!*txt) {
    strcpy((char *)out,"\\akks{");iB=6;
  } else if ( (*txt=='_')&&(txt[1]==0) ) {
    strcpy((char *)out,"\\akkt{");iB=6;
  } else {
    strcpy((char *)out,"\\akk{");iB=5;
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
    strcpy((char *)out+iB,"}{ }");iB+=4;
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

  xmlFree(txt);
  xmlFree(note);
  xmlXPathReturnString(ctxt, out);
}

static void functionHlpNLtxt(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=1) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need one argument\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }

  // Argumente holen
  xmlChar *str = xmlXPathPopString(ctxt);
  if (!str) {
    return;
  }

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

  xmlXPathReturnString(ctxt, str);
}

static void functionRepIt(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=2) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need two arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }

  // Argumente holen
  float fno = xmlXPathPopNumber(ctxt);
  if (xmlXPathCheckError(ctxt) || isnan(fno)) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"bad number\n");
    ctxt->error = XPATH_INVALID_OPERAND;
    return;
  }
  int no = (int)floor(fno + .5);
  if (no<0) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"number must be positive\n");
    ctxt->error = XPATH_INVALID_OPERAND;
    return;
  }
  xmlXPathObjectPtr obj1 = valuePop(ctxt);

  if (no==0) {
    xmlXPathFreeObject(obj1);
    xmlXPathReturnEmptyNodeSet(ctxt);
    return;
  } else if ( (obj1->type==XPATH_STRING)&&(obj1->stringval)&&(*obj1->stringval) ) {
    int len=xmlStrlen(obj1->stringval);
    xmlChar *ret=xmlMalloc(len*no+2),*tmp;
    for (tmp=ret;no>0;no--) {
      strcpy((char *)tmp,(char *)obj1->stringval);
      tmp+=len;
    }
    xmlXPathFreeObject(obj1);
    xmlXPathReturnString(ctxt, ret);
    return;
  } else if (xmlXPathNodeSetIsEmpty(obj1->nodesetval)) {
    valuePush(ctxt, obj1);
    return;
  }

  xsltTransformContextPtr tctxt;
  tctxt=xsltXPathGetTransformContext(ctxt);
  if (tctxt == NULL) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
        "RepIt : internal error tctxt == NULL\n");
    xmlXPathFreeObject(obj1);
    return;
  }

  int iA;
  xmlXPathObjectPtr ret = NULL;
  xmlDocPtr container;
  xmlNodePtr node;
  container = xsltCreateRVT(tctxt);
  if (container != NULL) {
    xsltRegisterLocalRVT(tctxt, container);
    ret = xmlXPathNewNodeSet(NULL);
    if (ret != NULL) {
      xmlNodeSetPtr nodelist=obj1->nodesetval;
      for (;no>0;no--) {
        for (iA=0;iA<nodelist->nodeNr;iA++) {
          node=xmlCopyNode(nodelist->nodeTab[iA],1);
          if (xmlAddChild((xmlNodePtr)container, node)==node) { // not merged
            xmlXPathNodeSetAdd(ret->nodesetval, node);
          }
        }
      }
    }
  }
  xmlXPathFreeObject(obj1);

  valuePush(ctxt, ret);
}

void *initSpeedExt(xsltTransformContextPtr ctxt, const xmlChar *URI)
{
  xsltRegisterExtFunction(ctxt,(xmlChar *)"subst_ul-kill_nl",URI,functionSubstKill);// tex
  xsltRegisterExtFunction(ctxt,(xmlChar *)"akk_subst_tex",URI,functionSubstAkkTex); // tex
  xsltRegisterExtFunction(ctxt,(xmlChar *)"nl_hlp",URI,functionHlpNLtxt);           // puretext
  xsltRegisterExtFunction(ctxt,(xmlChar *)"rep_it",URI,functionRepIt);              // general
  return NULL;
}
