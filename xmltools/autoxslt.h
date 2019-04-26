#ifndef _AUTOXSLT_H
#define _AUTOXSLT_H

#include <libxslt/xsltutils.h>
#include <libxslt/transform.h>
#include <memory>

class unique_xsltStylesheet { // {{{
public:
  unique_xsltStylesheet()=default;
  explicit unique_xsltStylesheet(xsltStylesheetPtr style) : ptr(style) {}

  operator xsltStylesheetPtr() const { return ptr.get(); }
  xsltStylesheetPtr operator->() const { return ptr.get(); }
  xsltStylesheetPtr release() { return ptr.release(); }
  void reset(xsltStylesheetPtr style=NULL) { ptr.reset(style); }

private:
  struct xsltStylesheet_deleter {
    void operator()(xsltStylesheetPtr style) {
      xsltFreeStylesheet(style);
    }
  };
  std::unique_ptr<xsltStylesheet,xsltStylesheet_deleter> ptr;
};
// }}}

class unique_xsltTransform { // {{{
public:
  unique_xsltTransform()=default;
  explicit unique_xsltTransform(xsltTransformContextPtr ctxt) : ptr(ctxt) {}

  operator xsltTransformContextPtr() const { return ptr.get(); }
  xsltTransformContextPtr operator->() const { return ptr.get(); }
  xsltTransformContextPtr release() { return ptr.release(); }
  void reset(xsltTransformContextPtr ctxt=NULL) { ptr.reset(ctxt); }

private:
  struct xsltTransformContextPtr_deleter {
    void operator()(xsltTransformContextPtr ctxt) {
      xsltFreeTransformContext(ctxt);
    }
  };
  std::unique_ptr<xsltTransformContext,xsltTransformContextPtr_deleter> ptr;
};
// }}}

#endif
