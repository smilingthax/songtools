#ifndef _AUTOXML_H
#define _AUTOXML_H

#include <libxml/tree.h>

class auto_xmlFree { // {{{
public:
  explicit auto_xmlFree() : data(NULL) {}
  explicit auto_xmlFree(void *data) : data(data) {}
  explicit auto_xmlFree(xmlChar *data) : data(data) {}
  ~auto_xmlFree() {
    xmlFree(data);
  }
  operator const char*() const {
    return (const char*)data;
  }
//  void *release();
  void reset(xmlChar *_data=NULL) {
    if (data!=_data) {
      xmlFree(data);
      data=_data;
    }
  }
private:
  auto_xmlFree(const auto_xmlFree &);
  const auto_xmlFree &operator=(const auto_xmlFree &);

  void *data;
};
// }}}

class auto_xmlDoc { // {{{
public:
  explicit auto_xmlDoc() : doc(NULL) {}
  explicit auto_xmlDoc(xmlDocPtr doc) : doc(doc) {}
  ~auto_xmlDoc() {
    xmlFreeDoc(doc);
  }
  operator xmlDocPtr&() {
    return doc;
  }
  const xmlDocPtr &operator->() const {
    return doc;
  }
  xmlDocPtr release() {
    xmlDocPtr ret=doc;
    doc=NULL;
    return ret;
  }
  void reset(xmlDocPtr _doc=NULL) {
    if (doc!=_doc) {
      xmlFree(doc);
      doc=_doc;
    }
  }
private:
  auto_xmlDoc(const auto_xmlDoc &);
  const auto_xmlDoc &operator=(const auto_xmlDoc &);

  xmlDocPtr doc;
};
// }}}

#endif
