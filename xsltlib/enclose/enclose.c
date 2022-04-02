/* Copyright by Tobias Hoffmann, Licence: LGPL/MIT, see COPYING
 * This file may, by your choice, be licensed under LGPL or by the MIT license.*/
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include <libxslt/variables.h>
#include <string.h>
#include "enclose.h"

xmlNodePtr xsltCopyTree(xsltTransformContextPtr ctxt, xmlNodePtr node, xmlNodePtr insert, int literal);

/**
 * thobiEncloseFunction:
 * @ctxt: an XPath parser context
 * @nargs: the number of arguments
 *
 * node-set ec:enclose(node-set,xpath-string,element-name-string)
 * xpath: has to return node-set with first element to be next split-point (relative to $ec:nodes)
 */
static void
thobiEncloseFunction(xmlXPathParserContextPtr ctxt, int nargs)
{
    xsltTransformContextPtr tctxt;
    xmlDocPtr container;
    xmlXPathObjectPtr ret = NULL,res;
    xmlNodeSetPtr inNodes;
    xmlXPathCompExprPtr comp;
    xmlNodePtr current=NULL,splitPt=NULL;
    xmlChar *str;
    const xmlChar *node_name;
    xsltStackElemPtr xp;
    xmlNsPtr ns=NULL;
    int last,iA;

    if (nargs!=3) {
      xmlXPathSetArityError(ctxt);
      return;
    }

    tctxt=xsltXPathGetTransformContext(ctxt);
    if (!tctxt) {
      xsltTransformError(xsltXPathGetTransformContext(ctxt),NULL,NULL,
                         "thax:enclose : internal error tctxt == NULL\n");
      return;
    }

    // TODO? do we want to suppress empty <...>?

    {
      xmlChar *tmp=xmlXPathPopString(ctxt);
      if (xmlXPathCheckError(ctxt)) {
        return;
      }
      if (xmlValidateQName(tmp,0)) {
        xsltTransformError(tctxt,NULL,NULL,
                           "thax:enclose : %s not a QName\n",tmp);
        xmlFree(tmp);
        return;
      }

      const xmlChar *prefix;
      node_name=xsltSplitQName(tctxt->dict,tmp,&prefix);
      xmlFree(tmp);
      if (prefix) {
        ns=xmlSearchNs(tctxt->style->doc,xmlDocGetRootElement(tctxt->style->doc),prefix);
        if (!ns) {
          xsltTransformError(tctxt,NULL,NULL,
                             "thax:enclose : prefix %s is not bound\n",prefix);
          return;
        }
      }
    }

    str=xmlXPathPopString(ctxt);
    if (xmlXPathCheckError(ctxt)) {
      xmlXPathSetTypeError(ctxt);
      return;
    }

    inNodes=xmlXPathPopNodeSet(ctxt);
    if (xmlXPathCheckError(ctxt)) {
      xmlFree(str);
      xmlXPathSetTypeError(ctxt);
      return;
    }

    if ( (!str)||(!str[0])||(!(comp=xmlXPathCompile(str))) ) {
      xmlXPathFreeNodeSet(inNodes);
      xmlFree(str);
      xsltTransformError(xsltXPathGetTransformContext(ctxt),NULL,NULL,
                         "thax:enclose : xpath expression failed\n");
      return;
    }

    xp=(xsltStackElemPtr)xmlMalloc(sizeof(xsltStackElem));
    if (!xp) {
      xsltTransformError(xsltXPathGetTransformContext(ctxt),NULL,NULL,
                         "thax:enclose : malloc failed\n");
      goto fail;
    }
    memset(xp,0,sizeof(xsltStackElem));
    xp->computed=1;
    xsltAddStackElemList(tctxt,xp);

    if ( (!inNodes)||(!inNodes->nodeNr) ) {
      goto fail;
    }

    container=xsltCreateRVT(tctxt);
    if (!container) {
      goto fail;
    }
    xsltRegisterLocalRVT(tctxt, container);
    ret=xmlXPathNewNodeSet(NULL);
    if (!ret) {
      goto fail;
    }

    xmlXPathNodeSetSort(inNodes);

    last=0;

    while (last<inNodes->nodeNr) {
      xmlXPathObjectPtr nodes;

      // generate a new current <...>-node
      current=xmlNewDocRawNode(container,ns,node_name,NULL);
      if (!current) {
        goto fail;
      }
      xmlAddChild((xmlNodePtr)container,current);
      xmlXPathNodeSetAddUnique(ret->nodesetval,current);

      nodes=xmlXPathNewNodeSet(NULL);
      if (!nodes) {
        goto fail;
      }
      for (iA=last; iA<inNodes->nodeNr; ++iA) {
        xmlXPathNodeSetAddUnique(nodes->nodesetval,inNodes->nodeTab[iA]);
      }

      // set/update variable $nodes in xpath context // alternative: set context accordingly!
      xp->name=xmlDictLookup(tctxt->dict,(const xmlChar *)"nodes",-1);
      xp->value=nodes;
      res=xmlXPathCompiledEval(comp,ctxt->context);
      xmlXPathFreeObject(nodes);
      xp->value=NULL;
      xp->name=NULL;

      // find next splitpoint
      if (res) {
        if ( (res->type!=XPATH_NODESET)||(!res->nodesetval) ) {
          xmlXPathFreeObject(res);
          xsltTransformError(xsltXPathGetTransformContext(ctxt),NULL,NULL,
                             "thax:enclose : xpath expression did not return a node-set\n");
          goto fail;
        }
        if (res->nodesetval->nodeNr>0) {
          splitPt=res->nodesetval->nodeTab[0];
        } else {
          splitPt=NULL;
        }
        xmlXPathFreeObject(res);
      }

      // split at that node by adding all content since last split
      for (iA=last; iA<inNodes->nodeNr; ++iA) {
        if (!inNodes->nodeTab[iA]) {
          continue;
        }
        if (inNodes->nodeTab[iA]==splitPt) { // fine
          // copy attributes
          xmlAttrPtr tmp=xmlCopyPropList(current,inNodes->nodeTab[iA]->properties);
          if (current->properties) {
            xsltTransformError(xsltXPathGetTransformContext(ctxt),NULL,NULL,
                               "thax:enclose : bug\n");
            goto fail;
          }
          current->properties=tmp;
          last=iA+1;
          break;
        }
        // copy the nodes
#if 0
        if ( (inNodes->nodeTab[iA]->type==XML_DOCUMENT_NODE)||
             (inNodes->nodeTab[iA]->type==XML_HTML_DOCUMENT_NODE) ) {
          xmlNodePtr tmp;
          for (tmp=inNodes->nodeTab[iA]->children;tmp;tmp=tmp->next) {
            xsltCopyTree(tctxt,tmp,current,0);
          }
        } else if (inNodes->nodeTab[iA]->type==XML_ATTRIBUTE_NODE) {
          // not allowed yet
          //xsltCopyProp(tctxt,current,(xmlAttrPtr)inNodes->nodeTab[iA]);
        } else {
          xsltCopyTree(tctxt,inNodes->nodeTab[iA],current,0);
        }
#else
        xmlNodePtr tmp=xmlCopyNode(inNodes->nodeTab[iA],1);
        xmlAddChild(current, tmp);
//      xmlXPathNodeSetAddUnique(ret->nodesetval,current); // TODO?
#endif
      }
      if (!splitPt) { // done
        break;
      }
      if (iA==inNodes->nodeNr) {
        // huh, splitPt not found
        xsltTransformError(xsltXPathGetTransformContext(ctxt),NULL,NULL,
                           "thax:enclose : returned splitpoint not found\n");
        goto fail;
      }
    }

fail:
    xmlXPathFreeCompExpr(comp);
    xmlXPathFreeNodeSet(inNodes);
    xmlFree(str);
    if (ret != NULL)
        valuePush(ctxt, ret);
    else
        valuePush(ctxt, xmlXPathNewNodeSet(NULL));
}

int load_enclose()
{
   xsltRegisterExtModuleFunction((const xmlChar *)"enclose",(const xmlChar *)"thax.home/enclose",thobiEncloseFunction);
   return 1;
}

#ifdef STANDALONE
int thax_home_enclose_init()
{
  return load_enclose();
}
#endif
