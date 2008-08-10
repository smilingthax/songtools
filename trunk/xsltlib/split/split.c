/* Copyright by Tobias Hoffmann, Licence: LGPL/MIT, see COPYING 
 * This file may, by your choice, be licensed under LGPL or by the MIT license */
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include <string.h>
#include "split.h"

/**
 * thobiStrSeparateFunction:
 * @ctxt: an XPath parser context
 * @nargs: the number of arguments
 *
 * Splits up a string on the characters of the delimiter string and returns a
 * node set of text nodes separated by <split char=""/> elements.
 */
static void
thobiStrSeparateFunction(xmlXPathParserContextPtr ctxt, int nargs)
{
    xsltTransformContextPtr tctxt;
    xmlChar *str, *delimiters, *cur,tmp[20];
    const xmlChar *token, *delimiter;
    xmlNodePtr node;
    xmlDocPtr container;
    xmlXPathObjectPtr ret = NULL;
    int clen;

    if ((nargs < 1) || (nargs > 2)) {
        xmlXPathSetArityError(ctxt);
        return;
    }

    if (nargs == 2) {
        delimiters = xmlXPathPopString(ctxt);
        if (xmlXPathCheckError(ctxt))
            return;
    } else {
        delimiters = xmlStrdup((const xmlChar *) "\t\r\n ");
    }
    if (delimiters == NULL)
        return;

// TODO: tree/ nodeSet
//    nodes=xmlXPathPopNodeSet(ctxt);
//    if (xmlXPathCheckError(ctxt)) {
//      xmlFree(delimiters);
//      return;
//    }
//    if ( (!nodes)||(nodes->nodeNr==0) ) {
//      goto fail;
//    }
    str = xmlXPathPopString(ctxt);
    if (xmlXPathCheckError(ctxt) || (str == NULL)) {
        xmlFree(delimiters);
        return;
    }

    /* Return a result tree fragment */
    tctxt = xsltXPathGetTransformContext(ctxt);
    if (tctxt == NULL) {
        xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
	      "exslt:tokenize : internal error tctxt == NULL\n");
	goto fail;
    }

    container = xsltCreateRVT(tctxt);
    if (container != NULL) {
        xsltRegisterTmpRVT(tctxt, container);
        ret = xmlXPathNewNodeSet(NULL);
        if (ret != NULL) {
            ret->boolval = 0; /* Freeing is not handled there anymore */
// TODO: traverse tree
//            for (int iA=0;iA<nodes->nodeNr;iA++) {
//            }
            for (cur = str, token = str; *cur != 0; cur += clen) {
	        clen = xmlUTF8Size(cur);
                for (delimiter = delimiters; *delimiter != 0; delimiter+=xmlUTF8Size(delimiter)) {
                    if (!xmlUTF8Charcmp(cur, delimiter)) {
                        // create pre text
                        if (cur != token) {
                            *cur = 0;
                            node = xmlNewDocText(container,token);
                            if (xmlAddChild((xmlNodePtr) container, node)==node) { // not merged
                                xmlXPathNodeSetAddUnique(ret->nodesetval, node);
                            }
                            *cur = *delimiter;
                        }
                        token = cur + clen;
                        // create <split>
                        node = xmlNewDocRawNode(container, NULL,
                                           (const xmlChar *) "split", NULL);
                        strncpy((char *)tmp,(const char*)delimiter,clen);
                        tmp[clen]=0;
                        xmlNewProp(node,(const xmlChar *)"char",tmp);
			xmlAddChild((xmlNodePtr) container, node);
			xmlXPathNodeSetAddUnique(ret->nodesetval, node);
                        break;
                    }
                }
            }
            if (token != cur) {
                node = xmlNewDocText(container,token);
                if (xmlAddChild((xmlNodePtr) container, node)==node) { // not merged
                    xmlXPathNodeSetAddUnique(ret->nodesetval, node);
                }
            }
        }
    }

fail:
    if (str != NULL)
        xmlFree(str);
    if (delimiters != NULL)
        xmlFree(delimiters);
    if (ret != NULL)
        valuePush(ctxt, ret);
    else
        valuePush(ctxt, xmlXPathNewNodeSet(NULL));
}

int load_split()
{
   xsltRegisterExtModuleFunction((const xmlChar *)"separate",(const xmlChar *)"thax.home/split",thobiStrSeparateFunction);
   return 1;
}

#ifdef STANDALONE
int thax_home_split_init()
{
  return load_split();
}
#endif
