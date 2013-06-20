#ifndef _XPATH_H
#define _XPATH_H

#include <string>
#include <libxml/tree.h>
#include <libxml/xpath.h>

class XPathContext {
public:
  XPathContext(xmlDocPtr doc);
  ~XPathContext();

  void setVariable(const char *name,const char *val);
  void setVariable(const char *name,double val);
  void clearVariables();

  std::string evalString(const char *str,xmlNodePtr=NULL);
//  ... evalNodeset(const char *str,xmlNodePtr=NULL);
  xmlNodePtr evalNode(const char *str,xmlNodePtr=NULL);

  // TODO?! var-arg  functions ('s_sprintf')
private:
  XPathContext(const XPathContext &);
  const XPathContext &operator=(const XPathContext &);

  xmlXPathContextPtr ctxt;
};

#endif
