/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include "process.h"
#include "parseakk.h"
//#include <vector>
//#include <map>
#include <string>
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
#include "autoxml.h"
#include "autoxslt.h"

using namespace std;

extern int xmlLoadExtDtdDefaultValue;
void init_transformer()
{
  xmlSubstituteEntitiesDefault(0);
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

bool do_transform(const char *inputFile,const char *outputFile,const char **interSheets,const char **secSheets,const char **secOutput,const char **params,int profile)
{
  int nbparams = 0;
  if (params) {
    for (;params[nbparams];nbparams++);
  }

  // Load input
  auto_xmlDoc doc, res;
  if (inputFile) {
//    doc.reset(xmlReadFile(inputFile,"iso-8859-1",0));
    doc.reset(xmlParseFile(inputFile));
  } else {
    doc.reset(xmlParseFile("songs.xml"));
  }
  if (!doc) {
    return false;
  }

  // Do the transform.
  printf("Processing shet.xsl\n");
  {
    auto_xsltStylesheet cur(xsltParseStylesheetFile((const xmlChar *)"shet.xsl"));
    auto_xsltTransform ctxt(xsltNewTransformContext(cur, doc));
    if (!ctxt) {
      return false;
    }
    res.reset(xsltApplyStylesheetUser(cur, doc, params, NULL, ((profile&1)?stderr:NULL), ctxt));
    if (!res) {
      return false;
    }
    if (outputFile) {
      const int tmp=xsltSaveResultToFilename(outputFile, res, cur,0);
  //    const int tmp=xsltSaveResultToFile(stdout, res, cur);
      if (tmp==-1) {
        return false;
      }
    }
    if (ctxt->state==XSLT_STATE_STOPPED) {  // e.g. xsl:message terminate
      return false;
    }
  }

  if (interSheets) {
    for (int iA=0; interSheets[iA]; iA++) {
      auto_xsltStylesheet cur(xsltParseStylesheetFile((const xmlChar *)interSheets[iA]));
      doc.reset(xsltApplyStylesheet(cur, res, params));
// TODO?! check  ctxt->state
      if (!doc) {
        return false;
      }
      res.reset(doc.release()); // TODO!? swap

      // HACK: sout.xml after transforms
      if ( (outputFile)&&(!interSheets[iA+1]) ) {
        const int tmp=xsltSaveResultToFilename(outputFile, res, cur,0);
        if (tmp==-1) {
          return false;
        }
      }
    }
  }

  if ( (!secSheets)||(!secOutput) ) {
    return true;
  }
  for (int iA=0; secSheets[iA] && secOutput[iA]; iA++) {
    printf("Processing %s\n",secSheets[iA]);
    auto_xsltStylesheet cur(xsltParseStylesheetFile((const xmlChar *)secSheets[iA]));
    auto_xsltTransform ctxt(xsltNewTransformContext(cur, res));
    if (!ctxt) {
      return false;
    }
    doc.reset(xsltApplyStylesheetUser(cur, res, params, NULL, ((profile&2)?stderr:NULL), ctxt));
    if (!doc) {
      return false;
    }
    const int tmp=xsltSaveResultToFilename(secOutput[iA], doc, cur,0);
    if (tmp==-1) {
      return false;
    }
    if (ctxt->state==XSLT_STATE_STOPPED) {  // e.g. xsl:message terminate
      return false;
    }
  }

  return true;
}

void end_transformer()
{
  xsltCleanupGlobals();
  xmlCleanupParser();
}

int do_process(char *inputFile,process_data_t *opts,const char *imgpath,const char *preset,const char *special)
{
  assert(opts);
  return do_process_hlp(inputFile,*opts,imgpath,preset,special);
}

std::string param_quote(const char *str)
{
  std::string ret;
  ret.assign("'");
  ret.append(str); // TODO?! also quote \' ?
  ret.append("'");
  return ret;
}

int do_process_hlp(char *inputFile,process_data_t &opts,const char *imgpath,const char *preset,const char *special)
{
  const char *interSheets[3],*secSheets[7],*secOutput[7];
  const char *params[16+1];

  init_transformer();
  if (!imgpath) {
    imgpath="/home/thobi/src/tsng";
  }
  path_register_prefix("img",imgpath);

  int iI=0;
  if (opts.inter_noshow) {
    interSheets[iI]="helper/no-show.xsl";
    iI++;
  }
  if (opts.inter_noakk) {
    interSheets[iI]="helper/no-akk.xsl";
    iI++;
  }
  interSheets[iI]=NULL;

  int iS=0;
  if (opts.out_html) {
    secSheets[iS]="hateemel.xsl";
    secOutput[iS]="list.htm";
    iS++;
  }
  if (opts.out_tex) {
    secSheets[iS]="tex.xsl";
    secOutput[iS]="in1.tex";
    iS++;
  }
  if (opts.out_plain) {
    secSheets[iS]="puretext.xsl";
    secOutput[iS]="plain";
    iS++;
  }
  if (opts.out_list) {
    secSheets[iS]="list.xsl";
    secOutput[iS]="list";
    iS++;
  }
  if (opts.out_impress) {
    secSheets[iS]="impress.xsl";
    secOutput[iS]="oolist";
    iS++;
  }
  if (opts.out_snippet) {
    secSheets[iS]="snippet.xsl";
    secOutput[iS]="snip.txt";
    iS++;
  }
  secSheets[iS]=NULL;
  secOutput[iS]=NULL;

  int iP=0;
  if (opts.split_impress) {
    params[iP]="out_split";
    iP++;
    params[iP]="'1'";
    iP++;
  }
  string ptmp,stmp; // must stay around ... bah
  if (preset) {
    params[iP]="presetname";
    iP++;
    // bah: we have to quote it
    ptmp=param_quote(preset);
    params[iP]=ptmp.c_str();
    iP++;
  }
  if (special) {
    params[iP]="allowSpecial";
    iP++;
    stmp=param_quote(special);
    params[iP]=stmp.c_str();
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
