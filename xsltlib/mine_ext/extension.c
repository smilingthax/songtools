/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include "extension.h"
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>

void *initMineExt(xsltTransformContextPtr ctxt, const xmlChar *URI)
{
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
