/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
//#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include "imagefun.h"
#include <string.h>

#ifdef LIBXML2_NEW_BUFFER
  #define xmlBufferLength xmlBufUse
  #define xmlBufferContent xmlBufContent
  #define xmlBufferShrink xmlBufShrink
#endif

static int xmlPIensure(xmlParserInputBufferPtr ibuf,int len)
{
  if (xmlBufferLength(ibuf->buffer)>=len) {
    return -1;
  }
  if ( (xmlParserInputBufferRead(ibuf,len)<=0)||(xmlBufferLength(ibuf->buffer)<len) ) {
    xmlFreeParserInputBuffer(ibuf);
    return 0;
  }
  return -1;
}

static char *png_sig="\211PNG\r\n\032\n";
#define png_IHDR 0x49484452
#define png_IEND 0x49454e44

// retlen>=20
static int get_png_size(const char *URI,xmlChar *retwidth,xmlChar *retheight,int retlen)
{
  const unsigned char *buf;
  int len,type,width,height;
  xmlParserInputBufferPtr ibuf;

  ibuf=xmlParserInputBufferCreateFilename(URI,XML_CHAR_ENCODING_NONE);
  if (!ibuf) {
    xsltTransformError(NULL,NULL,NULL,"image-size: Error opening \"%s\" for reading\n",URI);
    return -1;
  }

  // read signature(8) + first chunk(8+guess size: 13)
  if (!xmlPIensure(ibuf,29)) {
    return -1;
  }
  buf=(const unsigned char *)xmlBufferContent(ibuf->buffer);
  if (memcmp(buf,png_sig,8)!=0) {
    // Not a png
    xmlFreeParserInputBuffer(ibuf);
    return 1;
  }
  len=buf[11]+(buf[10]<<8)+(buf[9]<<16)+(buf[8]<<24);
  type=buf[15]+(buf[14]<<8)+(buf[13]<<16)+(buf[12]<<24);
  if ( (type==png_IHDR)&&(len==13) ) {
    buf+=16; // don't want to add it up...
    width=buf[3]+(buf[2]<<8)+(buf[1]<<16)+(buf[0]<<24);
    height=buf[7]+(buf[6]<<8)+(buf[5]<<16)+(buf[4]<<24);
#if 0
    fprintf(stderr,"\nWidth: %d, Height: %d, Bitdepth: %d, Colortype: %d, Compression: %d, Filter: %d, Interlace: %d\n",
            width,height,buf[8],buf[9],buf[10],buf[11],buf[12]);
#endif
    xmlStrPrintf(retwidth,retlen,"%d",width);
    xmlStrPrintf(retheight,retlen,"%d",height);
    xmlFreeParserInputBuffer(ibuf);
    return 0;
  }
  xmlFreeParserInputBuffer(ibuf);
  return 2;
}

#define jpeg_SOF0  0xffc0
#define jpeg_SOF3  0xffc0
#define jpeg_SOI   0xffd8
#define jpeg_EOI   0xffd9
#define jpeg_SOS   0xffda

#define jpeg_RST0  0xffd0
#define jpeg_RST7  0xffd7
#define jpeg_TEM   0xff01

static int get_jpeg_size(const char *URI,xmlChar *retwidth,xmlChar *retheight,int retlen)
{
  const unsigned char *buf;
  int len,marker,width,height;
  xmlParserInputBufferPtr ibuf;

  ibuf=xmlParserInputBufferCreateFilename(URI,XML_CHAR_ENCODING_NONE);
  if (!ibuf) {
    xsltTransformError(NULL,NULL,NULL,"image-size: Error opening \"%s\" for reading\n",URI);
    return -1;
  }

  // read "signature"(4)
  if (!xmlPIensure(ibuf,4)) {
    return -1;
  }
  buf=(const unsigned char *)xmlBufferContent(ibuf->buffer);
  marker=(buf[0]<<8)+buf[1];
  if ( (marker!=jpeg_SOI)||(buf[2]!=0xff) ) {
    // Not a jpeg
    xmlFreeParserInputBuffer(ibuf);
    return 1;
  }
  marker=(buf[2]<<8)+buf[3];
  xmlBufferShrink(ibuf->buffer,4);
  while (1) {
    if ( (marker==jpeg_EOI)||(marker==jpeg_SOS) ) {
      break;
    }
    if (  ( (marker>=jpeg_RST0)&&(marker<=jpeg_RST7) )||(marker==jpeg_TEM)  ) { // stand-alone marker
      if (!xmlPIensure(ibuf,2)) {
        return -1;
      }
      buf=(const unsigned char *)xmlBufferContent(ibuf->buffer);
      marker=(buf[0]<<8)+buf[1];
      xmlBufferShrink(ibuf->buffer,2);
      continue;
    }
    if (!xmlPIensure(ibuf,2)) {
      return -1;
    }
    buf=(const unsigned char *)xmlBufferContent(ibuf->buffer);
    len=(buf[0]<<8)+buf[1];
    xmlBufferShrink(ibuf->buffer,2);
    if ( (marker>=jpeg_SOF0)&&(marker<=jpeg_SOF3) ) { // only this formats, for now
      if (!xmlPIensure(ibuf,6)) {
        return -1;
      }
      buf=(const unsigned char *)xmlBufferContent(ibuf->buffer);
      height=(buf[1]<<8)+buf[2];
      width=(buf[3]<<8)+buf[4];
      xmlStrPrintf(retwidth,retlen,"%d",width);
      xmlStrPrintf(retheight,retlen,"%d",height);
      xmlFreeParserInputBuffer(ibuf);
      return 0;
    }
    if (!xmlPIensure(ibuf,len)) {
      return -1;
    }
    xmlBufferShrink(ibuf->buffer,len-2);
    buf=(const unsigned char *)xmlBufferContent(ibuf->buffer);
    marker=(buf[0]<<8)+buf[1];
    xmlBufferShrink(ibuf->buffer,2);
  }
  xmlFreeParserInputBuffer(ibuf);
  return 2;
}

static void
thobiImageSizeFunction(xmlXPathParserContextPtr ctxt, int nargs)
{
#define RETSIZE 20
  xmlChar *str,width[RETSIZE+1]="",height[RETSIZE+1]="";
  const xmlChar *type=NULL;
  int iA;

  if (nargs!=1) {
    xmlXPathSetArityError(ctxt);
    return;
  }

  str=xmlXPathPopString(ctxt);
  if ( (xmlXPathCheckError(ctxt))||(!str) ) {
    return;
  }

  // TODO: other formats than png,jpg
  iA=get_png_size((const char *)str,width,height,RETSIZE);
  if (iA==1) {
    iA=get_jpeg_size((const char *)str,width,height,RETSIZE);
    if (iA==0) {
      type=(const xmlChar *)"image/jpeg";
    }
  } else if (iA==0) {
    type=(const xmlChar *)"image/png";
  }
  xmlFree(str);
  if (iA!=0) { // error
    xsltTransformError(xsltXPathGetTransformContext(ctxt),NULL,NULL,"image-size: get_*_size error: %d\n",iA);
  } else {
    xsltTransformContextPtr tctxt;
    xmlDocPtr container;
    xmlXPathObjectPtr ret;
    xmlNodePtr node;

    tctxt=xsltXPathGetTransformContext(ctxt);
    if (!tctxt) {
      xsltTransformError(xsltXPathGetTransformContext(ctxt),NULL,NULL,"image-size: internal error tctxt == NULL\n");
      return;
    }
    container=xsltCreateRVT(tctxt);
    if (!container) {
      xsltTransformError(xsltXPathGetTransformContext(ctxt),NULL,NULL,"image-size: container==NULL\n");
      return;
    }
    xsltRegisterTmpRVT(tctxt,container);
    ret=xmlXPathNewNodeSet(NULL);
    if (!ret) {
      xsltTransformError(xsltXPathGetTransformContext(ctxt),NULL,NULL,"image-size: ret==NULL\n");
      return;
    }
    ret->boolval = 0; /* Freeing is not handled there anymore */

    // generate a new <image/>-node
    node=xmlNewDocRawNode(container,NULL,(const xmlChar *)"image",NULL);
    if (!node) {
      xsltTransformError(xsltXPathGetTransformContext(ctxt),NULL,NULL,"image-size: node==NULL\n");
      return;
    }
    xmlNewProp(node,(const xmlChar *)"width",width);
    xmlNewProp(node,(const xmlChar *)"height",height);
    if (type) {
      xmlNewProp(node,(const xmlChar *)"type",type);
    }
    xmlAddChild((xmlNodePtr)container,node);
    xmlXPathNodeSetAddUnique(ret->nodesetval,node);

    valuePush(ctxt,ret);
  }
}

int load_tools()
{
  xsltRegisterExtModuleFunction((const xmlChar *)"image-size",(const xmlChar *)"thax.home/tools",thobiImageSizeFunction);
  return 1;
}

#ifdef STANDALONE
int thax_home_tools_init()
{
  return load_tools();
}
#endif
