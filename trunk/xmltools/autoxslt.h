#ifndef _AUTOXSLT_H
#define _AUTOXSLT_H

#include <libxslt/xsltutils.h>

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
};
// }}}

#include <libxslt/transform.h>

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
};
// }}}

#endif
