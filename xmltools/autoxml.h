#ifndef _AUTOXML_H
#define _AUTOXML_H

#include <libxml/tree.h>
#include <memory>
#include <string>

class unique_xmlFree { // {{{
public:
  unique_xmlFree()=default;
//  explicit unique_xmlFree(void *data) : ptr(data) {}
  explicit unique_xmlFree(xmlChar *data) : ptr(data) {}

  operator const char *() const { return (const char *)ptr.get(); }
//  xmlChar *release() { return ptr.release(); } // or: void *
  void reset(xmlChar *data=NULL) { ptr.reset(data); }

  std::string str() const { return {*this}; } // only when non-nullptr!

private:
  struct xmlFree_deleter {
    void operator()(xmlChar *data) {
      xmlFree(data);
    }
  };
  std::unique_ptr<xmlChar,xmlFree_deleter> ptr; // or:  void *
};
// }}}

class unique_xmlDoc { // {{{
public:
  unique_xmlDoc()=default;
  explicit unique_xmlDoc(xmlDocPtr doc) : ptr(doc) {}

  operator xmlDocPtr() { return ptr.get(); }
  xmlDocPtr operator->() const { return ptr.get(); }
  xmlDocPtr release() { return ptr.release(); }
  void reset(xmlDocPtr doc=NULL) { ptr.reset(doc); }

private:
  struct xmlDoc_deleter {
    void operator()(xmlDocPtr doc) {
      xmlFreeDoc(doc);
    }
  };
  std::unique_ptr<xmlDoc,xmlDoc_deleter> ptr;
};
// }}}

// convenience; data must not be nullptr!
struct string_xmlFree : std::string {
  string_xmlFree(xmlChar *data) : std::string(unique_xmlFree(data)) {}
};

#endif
