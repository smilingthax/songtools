#ifndef _EXTENSION_H
#define _EXTENSION_H

#include <libxslt/transform.h>

#ifdef __cplusplus
 #include <vector>
 class SongContainer;
 class FlyTextTokens;
 extern std::vector<SongContainer *> songList;
 extern FlyTextTokens flyt;

extern "C" {
#endif
 int load_mine_ext();
 void *initMineExt(xsltTransformContextPtr ctxt, const xmlChar *URI);
 void *initSpeedExt(xsltTransformContextPtr ctxt, const xmlChar *URI);
// void endMineExt(xsltTransformContextPtr ctxt, const xmlChar *URI, void *data);

#ifdef __cplusplus
};
#endif

#endif
