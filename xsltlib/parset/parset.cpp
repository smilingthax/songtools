/* Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING */
#include <math.h>
#include <libxml/xmlmemory.h>
#include <libxml/xmlIO.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxslt/xslt.h>
#include <libxslt/xsltInternals.h>
#include <libxslt/transform.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include <libexslt/exslt.h>
#include "processor.h"
#include "parset.h"

extern "C" {
  void functionParset(xmlXPathParserContextPtr ctxt, int nargs);
#ifdef STANDALONE
  int thax_home_parset_init();
#endif
};

bool travAttr(ProcTraverse &proctrav,xmlAttrPtr attr,xmlXPathParserContextPtr ctxt)
{
  xmlChar *tmp;
  while (attr) {
    if (attr->type==XML_ATTRIBUTE_NODE) {
      tmp=xmlNodeListGetString(attr->doc,attr->children,0);
      proctrav.attrib(attr->name,tmp);
      xmlFree(tmp);
    } else {
      xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL, "not supported attribute type %d\n",attr->type);
      return false;
    }
    attr=attr->next;
  }
  return true;
}

bool traverse(ProcTraverse &proctrav,xmlNodePtr node,xmlXPathParserContextPtr ctxt)
{
  xmlNodePtr root=(node)?node->parent:NULL;
  while (node) {
    if (node->type==XML_ELEMENT_NODE) {
      proctrav.openNode(node->name);
      if (!travAttr(proctrav,node->properties,ctxt)) {
        return false;
      }
      if (!node->children) {
        proctrav.closeNode(node->name);
      } else {
        node=node->children;
        continue;
      }
//      traverse(proctrav,node->children);
//      proctrav.closeNode();
    } else if (node->type==XML_TEXT_NODE) {
      proctrav.text(node->content);
    } else if (node->type==XML_COMMENT_NODE) {
      proctrav.comment(node->content);
    } else {
      xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL, "not supported node type %d\n",node->type);
      return false;
    }
    while ( (node->parent!=root)&&(!node->next) ) {
      proctrav.closeNode(node->parent->name);
      node=node->parent;
    }
    node=node->next;
  }
  return true;
}

void functionParset(xmlXPathParserContextPtr ctxt, int nargs)
{
  if (nargs!=2) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,"need two arguments\n");
    ctxt->error = XPATH_INVALID_ARITY;
    return;
  }
  // Argumente holen
  xmlXPathObjectPtr obj2 = valuePop(ctxt);
  xmlXPathObjectPtr obj1 = valuePop(ctxt);
  xmlNodeSetPtr nodelist=obj1->nodesetval;

  if (xmlXPathNodeSetIsEmpty(nodelist)) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
        "Empty Nodeset not supported\n");
    return;
   // TODO
    xmlXPathFreeObject(obj2);
    if ( (obj1->type==XPATH_STRING)&&(obj1->stringval)&&(*obj1->stringval) ) {
      valuePush(ctxt, obj1);
      return;
    }
    valuePush(ctxt, obj1);
    return;
  }

  xsltTransformContextPtr tctxt;
  tctxt=xsltXPathGetTransformContext(ctxt);
  if (tctxt == NULL) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
        "internal error tctxt == NULL\n");
    return;
  }

  xmlChar *debug=xmlXPathCastToString(obj2);
  int iA;
  xmlXPathObjectPtr ret = NULL;
  xmlDocPtr container;
//  xmlNodePtr node;
  container = xsltCreateRVT(tctxt);
  if (container != NULL) {
    xsltRegisterLocalRVT(tctxt, container);
    ret = xmlXPathNewNodeSet(NULL);
    if (ret != NULL) {
      TreeBuilder tb(container,ret,debug,ctxt);
      ProcTraverse proctrav(tb);

      if ( (nodelist->nodeNr==1)&&(xmlStrEqual(nodelist->nodeTab[0]->name,(const xmlChar *)" fake node libxslt")) ) {
        // get rid of fake node
        traverse(proctrav,nodelist->nodeTab[0]->children,ctxt);
      } else {
        for (iA=0;iA<nodelist->nodeNr;iA++) {
          if (nodelist->nodeTab[iA]->type==XML_ELEMENT_NODE) {
            proctrav.openNode(nodelist->nodeTab[iA]->name);
            if (!travAttr(proctrav,nodelist->nodeTab[iA]->properties,ctxt)) {
              break;
            }
            if (!traverse(proctrav,nodelist->nodeTab[iA]->children,ctxt)) {
              break;
            }
            proctrav.closeNode(nodelist->nodeTab[iA]->name);
          } else if (nodelist->nodeTab[iA]->type==XML_TEXT_NODE) {
            proctrav.text(nodelist->nodeTab[iA]->content);
          } else if (nodelist->nodeTab[iA]->type==XML_COMMENT_NODE) {
          } else {
            xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                               "not supported node type %d\n",nodelist->nodeTab[iA]->type);
            break;
          }
          if (tb.has_error()) {
            break;
          }
        }
      }
    }
  }

  xmlFree(debug);
  xmlXPathFreeObject(obj1);
  xmlXPathFreeObject(obj2);
  if (ret) {
    valuePush(ctxt, ret);
  }
}

int load_parset()
{
  xsltRegisterExtModuleFunction((const xmlChar *)"parset",(const xmlChar *)"thax.home/parset",functionParset);
  return 1;
}

#ifdef STANDALONE
int thax_home_parset_init()
{
  return load_parset();
}
#endif
