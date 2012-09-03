#ifndef _AUTOXML_H
#define _AUTOXML_H

#include <libxml/tree.h>

#if defined(__GXX_EXPERIMENTAL_CXX0X__)||(__cplusplus>=201103L)
#include <memory>

class unique_xmlFree { // {{{
public:
  unique_xmlFree()=default;
//  explicit unique_xmlFree(void *data) : ptr(data) {}
  explicit unique_xmlFree(xmlChar *data) : ptr(data) {}

  inline operator const char *() const { return (const char *)ptr.get(); }
//  inline xmlChar *release() { return ptr.release(); } // or: void *
  inline void reset(xmlChar *data=NULL) { ptr.reset(data); }

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

  unique_xmlDoc(unique_xmlDoc &&doc) : ptr(std::move(doc.ptr)) {}
  unique_xmlDoc& operator=(unique_xmlDoc &&doc) {
    std::swap(ptr,doc.ptr);
    return *this;
  }

  inline operator xmlDocPtr() { return ptr.get(); }
  inline xmlDocPtr operator->() const { return ptr.get(); }
  inline xmlDocPtr release() { return ptr.release(); }
  inline void reset(xmlDocPtr doc=NULL) { ptr.reset(doc); }

private:
  struct xmlDoc_deleter {
    void operator()(xmlDocPtr doc) {
      xmlFreeDoc(doc);
    }
  };
  std::unique_ptr<xmlDoc,xmlDoc_deleter> ptr;
};
// }}}

#define _A_X_F_DEPR  __attribute__((deprecated))
#else
#define _A_X_F_DEPR
#endif

class auto_xmlFree { // {{{
public:
  explicit _A_X_F_DEPR auto_xmlFree() : data(NULL) {}
  explicit _A_X_F_DEPR auto_xmlFree(void *data) : data(data) {}
  explicit _A_X_F_DEPR auto_xmlFree(xmlChar *data) : data(data) {}
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
} _A_X_F_DEPR;
// }}}

class auto_xmlDoc { // {{{
public:
  explicit _A_X_F_DEPR auto_xmlDoc() : doc(NULL) {}
  explicit _A_X_F_DEPR auto_xmlDoc(xmlDocPtr doc) : doc(doc) {}
  ~auto_xmlDoc() {
    xmlFreeDoc(doc);
  }
  operator xmlDocPtr() {
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
      xmlFreeDoc(doc);
      doc=_doc;
    }
  }
private:
  auto_xmlDoc(const auto_xmlDoc &);
  const auto_xmlDoc &operator=(const auto_xmlDoc &);

  xmlDocPtr doc;
} _A_X_F_DEPR;
// }}}

#undef _A_X_F_DEPR

#endif
