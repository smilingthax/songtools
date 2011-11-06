#include "xpath.h"
#include <libxml/xpathInternals.h>
#include "exception.h"

using namespace std;

XPathContext::XPathContext(xmlDocPtr doc) // {{{
{
  ctxt=xmlXPathNewContext(doc);
  if (!ctxt) {
    throw UsrError("Error creating XPath context");
  }

  // need to register the namespaces
  xmlNodePtr tmp=xmlDocGetRootElement(doc);
  if (!tmp) {
    xmlXPathFreeContext(ctxt);
    throw logic_error("No Root Element");
  }
  for (xmlNsPtr ns=tmp->nsDef;ns;ns=ns->next) {
    if (xmlXPathRegisterNs(ctxt,ns->prefix,ns->href)!=0) {
      xmlXPathFreeContext(ctxt);
      throw UsrError("xmlXPathRegisterNs failed");
    }
  }
}
// }}}

XPathContext::~XPathContext() // {{{
{
  xmlXPathFreeContext(ctxt);
}
// }}}

void XPathContext::setVariable(const char *name,const char *val) // {{{
{
  xmlXPathObjectPtr obj=xmlXPathNewCString(val);
  xmlXPathRegisterVariable(ctxt,(const xmlChar *)name,obj);
}
// }}}

void XPathContext::setVariable(const char *name,double val) // {{{
{
  xmlXPathObjectPtr obj=xmlXPathNewFloat(val);
  xmlXPathRegisterVariable(ctxt,(const xmlChar *)name,obj);
}
// }}}

void XPathContext::clearVariables() // {{{
{
  xmlXPathRegisteredVariablesCleanup(ctxt);
}
// }}}

string XPathContext::evalString(const char *str,xmlNodePtr node) // {{{
{
  ctxt->node=node;
  xmlXPathObjectPtr res=xmlXPathEvalExpression((const xmlChar *)str,ctxt);
  if (!res) {
    throw UsrError("xpath eval failed with: \"%s\"",str);
  }

  string ret((const char *)xmlXPathCastToString(res));
  xmlXPathFreeObject(res);
  return ret;
}
// }}}

xmlNodePtr XPathContext::evalNode(const char *str,xmlNodePtr node) // {{{
{
  ctxt->node=node;
  xmlXPathObjectPtr res=xmlXPathEvalExpression((const xmlChar *)str,ctxt);
  if (!res) {
    throw UsrError("xpath eval failed with: \"%s\"",str);
  }

  xmlNodePtr ret=NULL;
  if ( (res->type==XPATH_NODESET)||(res->type==XPATH_XSLT_TREE) ) {
    if (res->nodesetval->nodeNr>=1)  {
      ret=res->nodesetval->nodeTab[0];
    }
  }
  xmlXPathFreeObject(res);
  return ret;
}
// }}}

#if 0 // TODO. What if not nodeset?
void XPathContext::evalNodeset(const char *str,xmlNodePtr node)
{
  ctxt->node=node;
  xmlXPathObjectPtr res=xmlXPathEvalExpression((const xmlChar *)str,ctxt);
  if (!res) {
    return NULL;
  }

ret=Song::to_string(xmlXPathCastToString(res));

  if ( (res->type==XPATH_NODESET)||(res->type==XPATH_XSLT_TREE) ) {
    if (res->nodesetval->nodeNr>=1)  {
      ret=res->nodesetval->nodeTab[0];
    }
  }
    if ( (res->type==XPATH_NODESET)||(res->type==XPATH_XSLT_TREE) ) {
        int iA;
            for (iA=0;iA<res->nodesetval->nodeNr;iA++) {
                  ret.push_back(res->nodesetval->nodeTab[iA]);
                      }
                        }
                          xmlXPathFreeObject(res);

  xmlXPathFreeObject(res);
}

// {{{ list<xmlNodePtr> evalXPathList(ctxt,node,expression,...)
list<xmlNodePtr> evalXPathList(xmlXPathContextPtr ctxt, xmlNodePtr node,const char *fmt,...)
{
  xmlXPathObjectPtr res;
  list<xmlNodePtr> ret;
  va_list ap;

  va_start(ap,fmt);
  char *query=a_vsprintf(fmt,ap);
  va_end(ap);
 
  ctxt->node=node;
  res=xmlXPathEvalExpression((const xmlChar *)query,ctxt);
  free(query);
  if (!res) {
    return ret;
//      throw UsrError("xmlXPathEvalExpression failed");
  }

  if ( (res->type==XPATH_NODESET)||(res->type==XPATH_XSLT_TREE) ) {
    int iA;
    for (iA=0;iA<res->nodesetval->nodeNr;iA++) {
      ret.push_back(res->nodesetval->nodeTab[iA]);
    }
  }
  xmlXPathFreeObject(res);
  return ret;
}
// }}}
#endif
