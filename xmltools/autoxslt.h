#ifndef _AUTOXSLT_H
#define _AUTOXSLT_H

#include <libxslt/xsltutils.h>

#include <libxslt/transform.h>

#if defined(__GXX_EXPERIMENTAL_CXX0X__)||(__cplusplus>=201103L)
#include <memory>

class unique_xsltStylesheet { // {{{
public:
  unique_xsltStylesheet()=default;
  explicit unique_xsltStylesheet(xsltStylesheetPtr style) : ptr(style) {}

  inline operator xsltStylesheetPtr() const { return ptr.get(); }
  inline xsltStylesheetPtr operator->() const { return ptr.get(); }
  inline xsltStylesheetPtr release() { return ptr.release(); }
  inline void reset(xsltStylesheetPtr style=NULL) { ptr.reset(style); }

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

  inline operator xsltTransformContextPtr() const { return ptr.get(); }
  inline xsltTransformContextPtr operator->() const { return ptr.get(); }
  inline xsltTransformContextPtr release() { return ptr.release(); } 
  inline void reset(xsltTransformContextPtr ctxt=NULL) { ptr.reset(ctxt); }

private:
  struct xsltTransformContextPtr_deleter {
    void operator()(xsltTransformContextPtr ctxt) {
      xsltFreeTransformContext(ctxt);
    }
  };
  std::unique_ptr<xsltTransformContext,xsltTransformContextPtr_deleter> ptr;
};
// }}}

#define _A_X_F_DEPR  __attribute__((deprecated))
#else
#define _A_X_F_DEPR
#endif

class auto_xsltStylesheet { // {{{
public:
  explicit auto_xsltStylesheet() : style(NULL) {}
  explicit auto_xsltStylesheet(xsltStylesheetPtr style) : style(style) {}
  ~auto_xsltStylesheet() {
    xsltFreeStylesheet(style);
  }
  operator xsltStylesheetPtr&() {
    return style;
  }
  const xsltStylesheetPtr &operator->() const {
    return style;
  }
  xsltStylesheetPtr release() {
    xsltStylesheetPtr ret=style;
    style=NULL;
    return ret;
  }
  void reset(xsltStylesheetPtr _style=NULL) {
    if (style!=_style) {
      xsltFreeStylesheet(style);
      style=_style;
    }
  }
private:
  auto_xsltStylesheet(const auto_xsltStylesheet &);
  const auto_xsltStylesheet &operator=(const auto_xsltStylesheet &);

  xsltStylesheetPtr style;
} _A_X_F_DEPR;
// }}}

class auto_xsltTransform { // {{{
public:
  explicit auto_xsltTransform() : ctxt(NULL) {}
  explicit auto_xsltTransform(xsltTransformContextPtr ctxt) : ctxt(ctxt) {}
  ~auto_xsltTransform() {
    xsltFreeTransformContext(ctxt);
  }
  operator xsltTransformContextPtr&() {
    return ctxt;
  }
  const xsltTransformContextPtr &operator->() const {
    return ctxt;
  }
  xsltTransformContextPtr release() {
    xsltTransformContextPtr ret=ctxt;
    ctxt=NULL;
    return ret;
  }
  void reset(xsltTransformContextPtr _ctxt=NULL) {
    if (ctxt!=_ctxt) {
      xsltFreeTransformContext(ctxt);
      ctxt=_ctxt;
    }
  }
private:
  auto_xsltTransform(const auto_xsltTransform &);
  const auto_xsltTransform &operator=(const auto_xsltTransform &);

  xsltTransformContextPtr ctxt;
} _A_X_F_DEPR;
// }}}

#undef _A_X_F_DEPR

#endif
