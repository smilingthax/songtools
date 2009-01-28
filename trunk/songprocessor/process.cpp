/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include "process.h"
#include "parseakk.h"
#include <vector>
#include <map>
#include <math.h>
//#include <libxml/xmlmemory.h>
//#include <libxml/xmlIO.h>
//#include <libxml/tree.h>
//#include <libxml/xpath.h>
//#include <libxml/xpathInternals.h>
//#include <libxslt/xslt.h>
//#include <libxslt/xsltInternals.h>
#include <libxslt/transform.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include <libexslt/exslt.h>
#include "xsltlib.h"

using namespace std;

extern int xmlLoadExtDtdDefaultValue;
void init_transformer()
{
  xmlSubstituteEntitiesDefault(1);
  xmlLoadExtDtdDefaultValue = 1;

//  xsltSetGenericDebugFunc(stderr, NULL);
  exsltRegisterAll();
  load_mine_ext();
  load_split();
  load_parset();
  load_doczip();
  load_enclose();
  load_tools();
  load_path();
#ifndef WIN32
  setenv("LIBXSLT_PLUGINS_PATH","",0); // avoid external plugins
#endif
}

bool do_transform(char *inputFile,char *outputFile,char **interSheets,char **secSheets,char **secOutput,const char **params,int profile)
{
  xsltStylesheetPtr cur = NULL, cur2;
  xmlDocPtr doc, res,res2;
  int iA;

  int nbparams = 0;
  if (params) {
    for (;params[nbparams];nbparams++);
  }

  // Do the transform.
  int theResult=0;
  cur = xsltParseStylesheetFile((xmlChar *)"shet.xsl");
  if (inputFile) {
//    doc = xmlReadFile(inputFile,"iso-8859-1",0); 
    doc = xmlParseFile(inputFile); 
  } else {
    doc = xmlParseFile("songs.xml");
  }
  if (!doc) {
    return false;
  }
  printf("Processing shet.xsl\n");
  if (profile&1) {
    xsltTransformContextPtr ctxt;
    ctxt = xsltNewTransformContext(cur, doc);
    if (ctxt == NULL) { 
      theResult=-1;
      return false;
    }
    res = xsltApplyStylesheetUser(cur, doc, params,NULL,stderr,ctxt);
    xsltFreeTransformContext(ctxt);
  } else {
    res = xsltApplyStylesheet(cur, doc, params);
  }
  if (!res) {
    theResult=-1;
  } else if (outputFile) {
    theResult=xsltSaveResultToFilename(outputFile, res, cur,0);
  }
  //  theResult=xsltSaveResultToFile(stdout, res, cur);
  xsltFreeStylesheet(cur);

  if (interSheets) {
    for (iA=0; interSheets[iA] &&(theResult!=-1); iA++) {
      cur2 = xsltParseStylesheetFile((xmlChar *)interSheets[iA]);
      res2 = xsltApplyStylesheet(cur2, res, params);
      if (!res2) {
        theResult=-1;
      } else { 
//        theResult=xsltSaveResultToFilename(secOutput[iA], res2, cur2,0);
        xmlFreeDoc(res);
        res = res2;
      }
      xsltFreeStylesheet(cur2);
    }
  }

  if ( (theResult==-1)||(!secSheets)||(!secOutput) ) { 
    xmlFreeDoc(res);
    xmlFreeDoc(doc);
    return (theResult!=-1);
  }
  for (iA=0; secSheets[iA] && secOutput[iA] &&(theResult!=-1) ; iA++) {
    cur2 = xsltParseStylesheetFile((xmlChar *)secSheets[iA]);
    printf("Processing %s\n",secSheets[iA]);
    if (profile&2) {
      xsltTransformContextPtr ctxt;
      ctxt = xsltNewTransformContext(cur2, res);
      if (ctxt == NULL) { 
        theResult=-1;
        return false;
      }
      res2 = xsltApplyStylesheetUser(cur2, res, params,NULL,stderr,ctxt);
      xsltFreeTransformContext(ctxt);
    } else {
      res2 = xsltApplyStylesheet(cur2, res, params);
// TODO: check ctxt->state==XSLT_STATE_STOPPED 
    }
    if (!res2) {
      theResult=-1;
    } else {
      theResult=xsltSaveResultToFilename(secOutput[iA], res2, cur2,0);
      xmlFreeDoc(res2);
    }
    xsltFreeStylesheet(cur2);
  }

  xmlFreeDoc(res);
  xmlFreeDoc(doc);

  return (theResult!=-1);
}

void end_transformer()
{
  xsltCleanupGlobals();
  xmlCleanupParser();
}

int do_process(char *inputFile,int tex,int plain,int html,int list,int impress,int split_impress,int snippet,const char *imgpath)
{
  return do_process_hlp(inputFile,(tex!=0),(plain!=0),(html!=0),(list!=0),(impress!=0),(snippet!=0),true,(split_impress!=0),imgpath);
}

int do_process_noakk(char *inputFile,int tex,int plain,int html,int list,int impress,int split_impress,int snippet,const char *imgpath)
{
  return do_process_hlp(inputFile,(tex!=0),(plain!=0),(html!=0),(list!=0),(impress!=0),(snippet!=0),false,(split_impress!=0),imgpath);
}

int do_process_hlp(char *inputFile,bool with_tex,bool with_plain,bool with_html,bool with_list,bool with_impress,bool with_snippet,bool with_akk,bool with_splitimpress,const char *imgpath)
{
  char *interSheets[3],*secSheets[7],*secOutput[7];
  const char *params[16+1];

  init_transformer();
  if (!imgpath) {
    imgpath="/home/thobi/src/tsng";
  }
  path_register_prefix("img",imgpath);

  if (!with_akk) {
    interSheets[0]="helper/no-akk.xsl";
    interSheets[1]=NULL;
  } else {
    interSheets[0]=NULL;
  }
  int iS=0;
  if (with_html) {
    secSheets[iS]="hateemel.xsl";
    secOutput[iS]="list.htm";
    iS++;
  }
  if (with_tex) {
    secSheets[iS]="tex.xsl";
    secOutput[iS]="in1.tex";
    iS++;
  }
  if (with_plain) {
    secSheets[iS]="puretext.xsl";
    secOutput[iS]="plain";
    iS++;
  }
  if (with_list) {
    secSheets[iS]="list.xsl";
    secOutput[iS]="list";
    iS++;
  }
  if (with_impress) {
    secSheets[iS]="impress.xsl";
    secOutput[iS]="oolist";
    iS++;
  }
  if (with_snippet) {
    secSheets[iS]="snippet.xsl";
    secOutput[iS]="snip.txt";
    iS++;
  }
  secSheets[iS]=NULL;
  secOutput[iS]=NULL;

  int iP=0;
  if (with_splitimpress) {
    params[iP]="out_split";
    iP++;
    params[iP]="1";
    iP++;
  }
  params[iP]=0;

  if (!do_transform(inputFile,"sout.xml",interSheets,secSheets,secOutput,params,0)) { // to profile: t3.xsl->1 secSheets->2 (ORed)
    printf("Error while transforming\n");
    end_transformer();
    return 1;
  }
  end_transformer();
  return 0;

//  AkkordItem ai;
//  akkParse(&ai,"Asus");
}
