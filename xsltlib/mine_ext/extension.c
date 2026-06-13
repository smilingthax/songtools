/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include "extension.h"
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include <assert.h>

// NOTE: <wchar.h> wcwidth() needs _XOPEN_SOURCE (posix)  -> not on win; setlocale() required
// - or: integrate https://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c ?
int simple_wcwidth(int ch)
{
  if (ch == 0) {
    return 0;
  } else if (ch < 32 || (ch >= 0x7f && ch < 0xa0)) {
    return -1;
  }
  return (ch >= 0x2e80 && ch <= 0xa4cf) ? 2 : 1;
  // + 0x1100 .. 0x11ff ?  (hangul jamo / korean)
  // + 0xac00 .. 0xd7a3 ?  (hangul)
  // + 0xf900 .. 0xfaff + ... ?
  // + 0x20000 .. 0x2fffd ?
  // + 0x30000 .. 0x3fffd ?
}

static void functionHasDoubleWidth(xmlXPathParserContextPtr ctxt, int nargs)
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

  int ret = 0, clen;
  xmlChar *cur;
  for (cur = str; *cur; cur += clen) {
    clen = 4; // libxml2 reads max. 4 (not 6) - and \0 will certainly terminate
    const int cp = xmlGetUTF8Char(cur, &clen);
    if (cp < 0) {
      xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"bad utf8\n");
      xmlFree(str);
      return;
    }

    const int w = simple_wcwidth(cp);
    assert(w<=2);
    if ( (ret==0)&&(w>0) ) {
      ret = 2*w;
    } else if ( (ret==2)&&(w==2) ) {
      ret = 3;
    } else if ( (ret==4)&&(w==1) ) {
      ret = 3;
    } // else: ignore (TODO?)
  }
  xmlFree(str);

  xmlXPathReturnNumber(ctxt, ret/2.0);
}

void *initMineExt(xsltTransformContextPtr ctxt, const xmlChar *URI)
{
  xsltRegisterExtFunction(ctxt,(xmlChar *)"has-double-width",URI,functionHasDoubleWidth);
  return NULL;
}

int load_mine_ext()
{
  xsltRegisterExtModule((xmlChar *)"thax.home/mine-akk",initMineAkk,NULL);
  xsltRegisterExtModule((xmlChar *)"thax.home/mine-ext",initMineExt,NULL);
  xsltRegisterExtModule((xmlChar *)"thax.home/mine-ext-speed",initSpeedExt,NULL);
  return 1;
}

#ifdef STANDALONE
int thax_home_mine_akk_init()
{
  return load_mine_ext();
}
int thax_home_mine_ext_init()
{
  return load_mine_ext();
}
int thax_home_mine_ext_speed_init()
{
  return load_mine_ext();
}
#endif
