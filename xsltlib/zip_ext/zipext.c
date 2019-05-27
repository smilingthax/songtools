/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include <string.h>
#include <libxml/xmlmemory.h>
#include <libxml/xmlIO.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxslt/xslt.h>
#include <libxslt/xsltInternals.h>
#include <libxslt/transform.h>
#include <libxslt/templates.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include <libexslt/exslt.h>
#include <zip.h>
#include <time.h>
#include "zipext.h"

#define MINE_NS "thax.home/zip-ext"

zipFile zipCur=0;

int XmlZipWrite(void *context, const char *buffer, int len)
{
  if (zipWriteInFileInZip((zipFile)context,&buffer[0],len)!=ZIP_OK) {
    return -1;
  }
  return len;
}

int XmlZipClose(void *context)
{
  if (zipCloseFileInZip((zipFile)context)!=ZIP_OK) {
    return -1;
  }
  return 0;
}

xmlOutputBufferPtr XmlZipCreate(const char *URI,xmlCharEncodingHandlerPtr encoder,int compression ATTRIBUTE_UNUSED)
{
  xmlOutputBufferPtr out;

  zip_fileinfo zi;
  struct tm *tm;
  time_t tt;

  int err;

  if (!zipCur) {
    return NULL;
  }

  // set up fileinfo
  time(&tt);
  tm=localtime(&tt);
  zi.tmz_date.tm_sec=tm->tm_sec;
  zi.tmz_date.tm_min=tm->tm_min;
  zi.tmz_date.tm_hour=tm->tm_hour;
  zi.tmz_date.tm_mday=tm->tm_mday;
  zi.tmz_date.tm_mon=tm->tm_mon;
  zi.tmz_date.tm_year=tm->tm_year;
  zi.dosDate=0;
  zi.internal_fa=zi.external_fa=0;

  if (strncmp(URI,"zip:store/",10)==0)  { // store only
    err=zipOpenNewFileInZip(zipCur,URI+10,&zi,NULL,0,NULL,0,NULL,0,0);
  } else {
//    err=zipOpenNewFileInZip(zipCur,URI,&zi,NULL,0,NULL,0,NULL,Z_DEFLATED,Z_DEFAULT_COMPRESSION);
    err=zipOpenNewFileInZip(zipCur,URI,&zi,NULL,0,NULL,0,NULL,Z_DEFLATED,9);
  }
  if (err!=ZIP_OK) {
    return NULL;
  }

  if ((out=xmlAllocOutputBuffer(NULL))==NULL) {
    zipCloseFileInZip(zipCur);
    return NULL;
  }
  out->context=(void *)zipCur;
  out->writecallback=XmlZipWrite;
  out->closecallback=XmlZipClose;

  return out;
}

typedef struct _docZipPreComp docZipPreComp;
struct _docZipPreComp {
  xsltElemPreComp comp;
  const xmlChar *filename;

  xmlXPathCompExprPtr cselect;
  xmlNsPtr *nsList;
  int nsNr;
};

void deallocDocZip(docZipPreComp *comp)
{
  if (!comp) {
    return;
  }
  if (comp->cselect) {
    xmlXPathFreeCompExpr(comp->cselect);
  }
  if (comp->nsList) {
    xmlFree(comp->nsList);
  }
  xmlFree(comp);
}

static int validate_get_only_copy(xmlNodePtr node,xmlNodeSetPtr nset)
{
  if (node->type!=XML_ELEMENT_NODE) {
    return 1;
  }
//TODO: if ((xmlStrEqual(test->ns->href, EXSLT_COMMON_NAMESPACE))&&
  if (xmlStrEqual(node->name,(const xmlChar *)"copy")) {
    if ( (!node->children)&&(xmlGetProp(node,(const xmlChar *)"fromhref"))&&(xmlGetProp(node,(const xmlChar *)"tohref")) ) { // no children, has @fromhref, @tohref
      xmlXPathNodeSetAdd(nset,node);
      return 1;
    }
  }
  return 0;
}

void elementDocZipElem(xsltTransformContextPtr ctxt, xmlNodePtr node, xmlNodePtr inst, docZipPreComp *comp)
{
  xmlOutputBufferCreateFilenameFunc old=NULL;
  xmlChar *URI;
  xmlXPathObjectPtr cselobj=NULL;
  int iA;

  if ( (!ctxt)||(!node)||(!inst)||(!comp)||
       (comp->comp.free!=(xsltElemPreCompDeallocator)deallocDocZip) ) { // no my data (hmm...)
    return;
  }
  if (!comp->filename) {
    URI=xsltEvalAttrValueTemplate(ctxt,inst,(const xmlChar *)"href",(const xmlChar*)MINE_NS);
    if (!URI) {
      xsltTransformError(ctxt,NULL,inst,"doc-zip: @href needed\n");
      return;
    }
  } else {
    URI=xmlStrdup(comp->filename);
  }
  if (comp->cselect) {
    xmlNsPtr *oldNsList;
    int oldNsNr;
    xmlNodePtr test;
    xmlNodeSetPtr nlist;

    oldNsList=ctxt->xpathCtxt->namespaces;
    oldNsNr=ctxt->xpathCtxt->nsNr;
    ctxt->xpathCtxt->namespaces=comp->nsList;
    ctxt->xpathCtxt->nsNr=comp->nsNr;
    cselobj=xmlXPathCompiledEval(comp->cselect,ctxt->xpathCtxt);
    ctxt->xpathCtxt->nsNr=oldNsNr;
    ctxt->xpathCtxt->namespaces=oldNsList;
    if (!cselobj) {
      xsltTransformError(ctxt,NULL,inst,"doc-zip: ret == NULL\n");
      xmlFree(URI);
      return;
    }
    if (  (cselobj->type==XPATH_STRING)&&( (!cselobj->stringval)||(!*cselobj->stringval) )  ) { // empty string, -> skip
      xmlXPathFreeObject(cselobj);
      cselobj=NULL;
      goto emptylist;
    }
    // check, that it is a RVT or NodeSet containing only <copy fromhref="" tohref=""/>
    if ( (cselobj->type!=XPATH_NODESET)&&(cselobj->type!=XPATH_XSLT_TREE) ) {
      xsltTransformError(ctxt,NULL,inst,"doc-zip: @copy-select is not a Tree or NodeSet\n");
      xmlFree(URI);
      xmlXPathFreeObject(cselobj);
      return;
    }
    // ok get the files into a temporary list
    nlist=xmlXPathNodeSetCreate(NULL);
    if (!nlist) {
      xsltTransformError(ctxt,NULL,inst,"doc-zip: nlist == NULL\n");
      xmlFree(URI);
      xmlXPathFreeObject(cselobj);
      return;
    }
    for (iA=0;iA<cselobj->nodesetval->nodeNr;iA++) {
      // only allowed childrens <copy>
      if (xmlStrEqual(cselobj->nodesetval->nodeTab[iA]->name,(const xmlChar *)" fake node libxslt")) {
        for (test=cselobj->nodesetval->nodeTab[iA]->children;test;test=test->next) {
          if (validate_get_only_copy(test,nlist)) {
            continue;
          }
          break;
        }
        if (!test) {
          continue;
        }
      } else {
        if (validate_get_only_copy(cselobj->nodesetval->nodeTab[iA],nlist)) {
          continue;
        }
      }
      xsltTransformError(ctxt,NULL,inst,"doc-zip: only copy-elements allowed in @copy-select, having @fromhref and @tohref \n");
      xmlFree(URI);
      xmlXPathFreeObject(cselobj);
      xmlXPathFreeNodeSet(nlist);
      return;
    }
    // hack... exchange the node-set!
    xmlXPathFreeNodeSet(cselobj->nodesetval);
    cselobj->nodesetval=nlist;
  }
emptylist:

  // Activate zip stream
  if (zipCur) {
    xsltTransformError(ctxt,NULL,inst,"doc-zip: zip Stream is already active!\n");
    xmlFree(URI);
    if (cselobj) {
      xmlXPathFreeObject(cselobj);
    }
    return;
  }
  if ((zipCur=zipOpen((const char *)URI,APPEND_STATUS_CREATE))==NULL) {
    xsltTransformError(ctxt,NULL,inst,"doc-zip: Error opening \"%s\"\n",URI);
    xmlFree(URI);
    if (cselobj) {
      xmlXPathFreeObject(cselobj);
    }
    return;
  }
  old=xmlOutputBufferCreateFilenameDefault(XmlZipCreate);
  xsltApplyOneTemplate(ctxt, ctxt->node, inst->children, NULL, NULL);
  // add files from @copy-select; do it _last_
  if (cselobj) {
    xmlOutputBufferPtr obuf;
    xmlParserInputBufferPtr ibuf;
    size_t len;

    for (iA=0;iA<cselobj->nodesetval->nodeNr;iA++) { // everything is a ELEMENT, and no fake nodes, Yes!
      xmlNodePtr test=cselobj->nodesetval->nodeTab[iA];
      // it is a <copy> -element... as checked above
      obuf=xmlOutputBufferCreateFilename((const char *)xmlGetProp(test,(const xmlChar *)"tohref"),NULL,0);// TODO? xmlCanonicPath(URL)
      if (!obuf) {
        xsltTransformError(ctxt,NULL,inst,"doc-zip: @copy-select: Error opening \"%s\" for writing\n",xmlGetProp(test,(const xmlChar *)"tohref"));
        xmlFree(URI);
        xmlXPathFreeObject(cselobj);
        return;
      }
      ibuf=xmlParserInputBufferCreateFilename((const char *)xmlGetProp(test,(const xmlChar *)"fromhref"),XML_CHAR_ENCODING_NONE);
      if (!ibuf) {
        xsltTransformError(ctxt,NULL,inst,"doc-zip: @copy-select: Error opening \"%s\" for reading\n",xmlGetProp(test,(const xmlChar *)"fromhref"));
        xmlFree(URI);
        xmlXPathFreeObject(cselobj);
        xmlOutputBufferClose(obuf);
        return;
      }
      // copy contents verbatim
      while (xmlParserInputBufferRead(ibuf,2048)>0) {
#ifdef LIBXML2_NEW_BUFFER
        len=xmlBufUse(ibuf->buffer);
        xmlOutputBufferWrite(obuf,len,(const char *)xmlBufContent(ibuf->buffer));
        xmlBufShrink(ibuf->buffer,len);
#else
        len=xmlBufferLength(ibuf->buffer);
        xmlOutputBufferWrite(obuf,len,(const char *)xmlBufferContent(ibuf->buffer));
        xmlBufferShrink(ibuf->buffer,len);
#endif
      }
      xmlFreeParserInputBuffer(ibuf);
      xmlOutputBufferClose(obuf);
    }
    xmlXPathFreeObject(cselobj);
  }
  xmlOutputBufferCreateFilenameDefault(old);
  zipClose(zipCur,NULL);
  zipCur=0;
  xmlFree(URI);
}

xsltElemPreCompPtr elementDocZipComp(xsltStylesheetPtr style, xmlNodePtr inst, xsltTransformFunction function)
{
  int iA;
  xmlNodePtr test;
  docZipPreComp *comp;
  xmlChar *sel;

  // only allowed childrens <exsl:document>
  for (test=inst->children;test;test=test->next) {
    if (test->type != XML_ELEMENT_NODE) {
      continue;
    }
    if ((xmlStrEqual(test->ns->href, EXSLT_COMMON_NAMESPACE))&&
        (xmlStrEqual(test->name, (const xmlChar *) "document")) ) {
      continue;
    }
    xsltTransformError(NULL,style,inst,"doc-zip: only xsl:document allowed\n");
    return NULL;
  }

  // alloc struct
  comp=(docZipPreComp *)xmlMalloc(sizeof(docZipPreComp));
  if (!comp) {
    xsltTransformError(NULL,style,NULL,"doc-zip : malloc failed\n");
    return NULL;
  }
  memset(comp,0,sizeof(docZipPreComp));
  xsltInitElemPreComp((xsltElemPreCompPtr)comp,style,inst,function,(xsltElemPreCompDeallocator)deallocDocZip);
  // now it will get freed

  // get href
  comp->filename=xsltEvalStaticAttrValueTemplate(style,inst,(const xmlChar *)"href",(const xmlChar *)MINE_NS,&iA);

  // get copy-select
  sel=xmlGetNsProp(inst,(const xmlChar *)"copy-select",NULL);
  if (sel) {
    comp->cselect=xmlXPathCompile(sel);
    xmlFree(sel);
  }
  // and the namespace-list
  comp->nsList=xmlGetNsList(inst->doc,inst);
  if (comp->nsList) {
    for (iA=0;comp->nsList[iA];iA++);
    comp->nsNr=iA;
  }

  return (xsltElemPreCompPtr)comp;
}

int load_doczip()
{
  xsltRegisterExtModuleElement((const xmlChar *)"doc-zip",(const xmlChar *)MINE_NS,elementDocZipComp,(xsltTransformFunction)elementDocZipElem);
  return 1;
}

#ifdef STANDALONE
void thax_home_zip_ext_init()
{
  load_doczip();
}
#endif
