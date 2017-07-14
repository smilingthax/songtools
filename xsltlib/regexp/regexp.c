/* Copyright by Tobias Hoffmann, Licence: LGPL/MIT, see COPYING
 * This file may, by your choice, be licensed under LGPL or by the MIT license */
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include <string.h>
#include "regexp.h"

#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>

enum flag_t {
  FLAG_NONE   = 0,
  FLAG_GLOBAL = 0x01,
  FLAG_ICASE  = 0x02
};

static int parse_flags(const char *str) // {{{  or -1
{
  // assert(str);
  int ret = FLAG_NONE;
  for (; *str; ++str) {
    if (*str == 'g') {
      ret |= FLAG_GLOBAL;
    } else if (*str == 'i') {
      ret |= FLAG_ICASE;
    } else {
      return -1;
    }
  }
  return ret;
}
// }}}

// create <match @no>...
static void create_match(xmlDocPtr doc, xmlNodeSetPtr nodeset, int no, const xmlChar *str, int len) // {{{
{
  xmlNodePtr node = xmlNewDocRawNode(doc, NULL, (const xmlChar *) "match", NULL);

  if (len > 0) {
    xmlNodePtr text = xmlNewDocTextLen(doc, str, len);
    xmlAddChild(node, text);
  }

  if (no) {
    char buf[20];
    snprintf(buf, 20, "%d", no);
    xmlSetProp(node, (const xmlChar *)"no", (const xmlChar *)buf);
  }

  xmlAddChild((xmlNodePtr)doc, node);
  xmlXPathNodeSetAddUnique(nodeset, node);
}
// }}}

static void set_error(xmlXPathParserContextPtr ctxt, const char *name, const char *what, int pcre_err) // {{{
{
  char buf[250];
  pcre2_get_error_message(pcre_err, (unsigned char *)buf, sizeof(buf));
  xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                     "regexp:%s : %s: %s\n", name, what, buf);
}
// }}}

static pcre2_code *do_compile(xmlXPathParserContextPtr ctxt, const xmlChar *regexp, int icase) // {{{
{
  int err;
  PCRE2_SIZE erroffset;

  uint32_t opts = PCRE2_UTF | PCRE2_ALT_BSUX | PCRE2_NEVER_BACKSLASH_C;
  if (icase) {
    opts |= PCRE2_CASELESS;
  }

  pcre2_compile_context *cctx = pcre2_compile_context_create(NULL);
  if (!cctx) {
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                       "regexp : pcre2 compile_context_create failed\n");
    return NULL;
  }
  pcre2_set_newline(cctx, PCRE2_NEWLINE_ANY);
  pcre2_code *re = pcre2_compile(regexp, PCRE2_ZERO_TERMINATED, opts, &err, &erroffset, cctx);
  pcre2_compile_context_free(cctx);

  if (!re) {
    char buf[250];
    int len = pcre2_get_error_message(err, (unsigned char *)buf, sizeof(buf)-20);
    if (len > 0) {
      snprintf(buf+len, sizeof(buf)-len, " at %d", erroffset);
    }
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                       "regexp : pcre2 compile failed: %s\n", buf);
    return NULL;
  }
  return re;
}
// }}}

static void regexp_test(xmlXPathParserContextPtr ctxt, const xmlChar *str, const xmlChar *regexp, enum flag_t flags) // {{{
{
  // (ignores FLAG_GLOBAL)
  pcre2_code *re = do_compile(ctxt, regexp, (flags&FLAG_ICASE));
  if (!re) {
    return;
  }

  pcre2_match_data *match = pcre2_match_data_create(2, NULL);
  if (!match) {
    pcre2_code_free(re);
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                       "regexp:test : pcre2 match_data_create failed\n");
    return;
  }

  int err = pcre2_match(re, str, PCRE2_ZERO_TERMINATED, 0, 0, match, NULL);

  pcre2_match_data_free(match);
  pcre2_code_free(re);

  if (err == PCRE2_ERROR_NOMATCH) {
    xmlXPathReturnBoolean(ctxt, 0);
  } else if (err < 0) {
    set_error(ctxt, "test", "pcre2 match failed", err);
  } else {
    xmlXPathReturnBoolean(ctxt, 1);
  }
}
// }}}

static void regexp_match(xmlXPathParserContextPtr ctxt, const xmlChar *str, const xmlChar *regexp, enum flag_t flags, xmlDocPtr doc, xmlNodeSetPtr nodeset) // {{{
{
  pcre2_code *re = do_compile(ctxt, regexp, (flags&FLAG_ICASE));
  if (!re) {
    return;
  }

  pcre2_match_data *match;
  if (flags&FLAG_GLOBAL) {
    // different output fmt, captures are not used
    match = pcre2_match_data_create(2, NULL);
  } else {
    match = pcre2_match_data_create_from_pattern(re, NULL);
  }
  if (!match) {
    pcre2_code_free(re);
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                       "regexp:match : pcre2 match_data_create failed\n");
    return;
  }

  int err = pcre2_match(re, str, PCRE2_ZERO_TERMINATED, 0, 0, match, NULL);

  if (err < 0) {
    pcre2_match_data_free(match);
    pcre2_code_free(re);

    if (err != PCRE2_ERROR_NOMATCH) {
      set_error(ctxt, "match", "pcre2 match failed", err);
    }
    return;
  }

  PCRE2_SIZE *mvec = pcre2_get_ovector_pointer(match);

  if ((flags&FLAG_GLOBAL)==0) {
    uint32_t mlen = pcre2_get_ovector_count(match);
    for (uint32_t i=0; i<mlen; i++) {
      create_match(doc, nodeset, 0, str+mvec[2*i], mvec[2*i+1]-mvec[2*i]);
    }

    pcre2_match_data_free(match);
    pcre2_code_free(re);
    return;
  }

  // handle Global
  create_match(doc, nodeset, 0, str+mvec[0], mvec[1]-mvec[0]);

  uint32_t opts;
  unsigned int offset = mvec[1];
  while (1) {
    if (mvec[0] == offset) {
      if (!str[offset]) { // done
        break;
      }
      // we got an empty match, retry to find a non-empty one
      opts = PCRE2_NOTEMPTY_ATSTART | PCRE2_ANCHORED;
    } else {
      opts = 0;
    }

    err = pcre2_match(re, str, PCRE2_ZERO_TERMINATED, offset, opts, match, NULL);

    if (err == PCRE2_ERROR_NOMATCH) {
      if (!opts) { // not a retry. we're done.
        break;
      } // else: we tried to find non-empty match, but it didn't match
      // -> advance one char (skip CRLF / UTF-8!) and continue normally
      if ( (str[offset]=='\r')&&(str[offset+1]=='\n') ) {
        offset += 2;
      } else {
        offset++;
        while ((str[offset]&0xc0) == 0x80) { // skip full utf8
          offset++;
        }
      }
    } else if (err < 0) {
      pcre2_match_data_free(match);
      pcre2_code_free(re);
      set_error(ctxt, "match", "pcre2 match failed", err);
      return;
    } else {
      create_match(doc, nodeset, 0, str+mvec[0], mvec[1]-mvec[0]);
      offset = mvec[1];
    }
  }

  pcre2_match_data_free(match);
  pcre2_code_free(re);
}
// }}}

static void regexp_split(xmlXPathParserContextPtr ctxt, const xmlChar *str, const xmlChar *regexp, enum flag_t flags, xmlDocPtr doc, xmlNodeSetPtr nodeset) // {{{
{
  // (implicitly FLAG_GLOBAL)
  pcre2_code *re = do_compile(ctxt, regexp, (flags&FLAG_ICASE));
  if (!re) {
    return;
  }

  pcre2_match_data *match = pcre2_match_data_create_from_pattern(re, NULL);
  if (!match) {
    pcre2_code_free(re);
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                       "regexp:split : pcre2 match_data_create failed\n");
    return;
  }

  int err = pcre2_match(re, str, PCRE2_ZERO_TERMINATED, 0, 0, match, NULL);

  if (err < 0) {
    pcre2_match_data_free(match);
    pcre2_code_free(re);
    if (err == PCRE2_ERROR_NOMATCH) {
      // create text node
      if (*str) {
        xmlNodePtr node = xmlNewDocText(doc, str);
        if (xmlAddChild((xmlNodePtr)doc, node)==node) { // not merged
          xmlXPathNodeSetAddUnique(nodeset, node);
        }
      }
    } else {
      set_error(ctxt, "split", "pcre2 match failed", err);
    }
    return;
  }

  PCRE2_SIZE *mvec = pcre2_get_ovector_pointer(match);
  uint32_t mlen = pcre2_get_ovector_count(match);

  // create text node
  if (mvec[0] > 0) {
    xmlNodePtr node = xmlNewDocTextLen(doc, str, mvec[0]);
    if (xmlAddChild((xmlNodePtr)doc, node)==node) { // not merged
      xmlXPathNodeSetAddUnique(nodeset, node);
    }
  }
  if (mlen <= 1) {
    create_match(doc, nodeset, 0, 0, 0); // just <match/>
  } else {
    for (uint32_t i=1; i<mlen; i++) {
      // possibly PCRE2_UNSET!
      create_match(doc, nodeset, i, str+mvec[2*i], mvec[2*i+1]-mvec[2*i]);
    }
  }

  uint32_t opts;
  unsigned int offset = mvec[1];
  while (1) {
    if (mvec[0] == offset) {
      if (!str[offset]) { // done
        break;
      }
      // we got an empty match, retry to find a non-empty one
      opts = PCRE2_NOTEMPTY_ATSTART | PCRE2_ANCHORED;
    } else {
      opts = 0;
    }

    err = pcre2_match(re, str, PCRE2_ZERO_TERMINATED, offset, opts, match, NULL);

    if (err == PCRE2_ERROR_NOMATCH) {
      if (!opts) { // not a retry. we're done.
        // create text node
        if (str[offset]) {
          xmlNodePtr node = xmlNewDocText(doc, str+offset);
          if (xmlAddChild((xmlNodePtr)doc, node)==node) { // not merged
            xmlXPathNodeSetAddUnique(nodeset, node);
          }
        }
        break;
      } // else: we tried to find non-empty match, but it didn't match
      // -> advance one char (skip CRLF / UTF-8!) and continue normally
      const unsigned int pos = offset;
      if ( (str[offset]=='\r')&&(str[offset+1]=='\n') ) {
        offset += 2;
      } else {
        offset++;
        while ((str[offset]&0xc0) == 0x80) { // skip full utf8
          offset++;
        }
      }
      // append text - libxml will merge nodes ...
      xmlNodePtr node = xmlNewDocTextLen(doc, str+pos, offset-pos);
      if (xmlAddChild((xmlNodePtr)doc, node)==node) { // not merged
        xmlXPathNodeSetAddUnique(nodeset, node);
      }
    } else if (err < 0) {
      pcre2_match_data_free(match);
      pcre2_code_free(re);
      set_error(ctxt, "split", "pcre2 match failed", err);
      return;
    } else {
      // create text node
      if (mvec[0] > offset) {
        xmlNodePtr node = xmlNewDocTextLen(doc, str+offset, mvec[0]-offset);
        if (xmlAddChild((xmlNodePtr)doc, node)==node) { // not merged
          xmlXPathNodeSetAddUnique(nodeset, node);
        }
      }

      mlen = pcre2_get_ovector_count(match);
      if (mlen <= 1) {
        create_match(doc, nodeset, 0, 0, 0); // just <match/>
      } else {
        for (uint32_t i=1; i<mlen; i++) {
          // possibly PCRE2_UNSET!
          create_match(doc, nodeset, i, str+mvec[2*i], mvec[2*i+1]-mvec[2*i]);
        }
      }
      offset = mvec[1];
    }
  }

  pcre2_match_data_free(match);
  pcre2_code_free(re);
}
// }}}

/**
 * thobiRegexpTestFunction:
 * @ctxt: an XPath parser context
 * @nargs: the number of arguments
 *
 * boolean regexp:test(string input, string regexp, string? flags)
 */
static void
thobiRegexpTestFunction(xmlXPathParserContextPtr ctxt, int nargs) // {{{
{
    xmlChar *str = NULL, *rxp = NULL;

    if ((nargs < 2) || (nargs > 3)) {
        xmlXPathSetArityError(ctxt);
        return;
    }

    int flags;
    if (nargs == 3) {
        xmlChar *tmp = xmlXPathPopString(ctxt);
        if ( (xmlXPathCheckError(ctxt))||(!tmp) ) {
           return;
        }
        flags = parse_flags((const char *)tmp);
        if (flags < 0) {
            xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                "regexp:test : unknown flag given (only 'gi' are supported)\n");
            xmlFree(tmp);
            return;
        }
        xmlFree(tmp);
    } else {
        flags = FLAG_NONE;
    }

    rxp = xmlXPathPopString(ctxt);
    if ( (xmlXPathCheckError(ctxt))||(!rxp) ) {
        return;
    }

    str = xmlXPathPopString(ctxt);
    if ( (xmlXPathCheckError(ctxt))||(!str) ) {
        xmlFree(rxp);
        return;
    }

    regexp_test(ctxt, str, rxp, flags);

    xmlFree(str);
    xmlFree(rxp);
}
// }}}

/**
 * thobiRegexpMatchFunction:
 * @ctxt: an XPath parser context
 * @nargs: the number of arguments
 *
 * object regexp:match(string input, string regexp, string? flags)
 *
 * Returns <match>...</match><match>...</match>...,
 * where, when flags contain 'g':
 *    [1]... = 1st(2nd, ...) full match of regexp
 *
 * and, when flags do not contain 'g':
 *    [1] = full match,  [2]...[n+1] = capture group 1...n
 */
static void
thobiRegexpMatchFunction(xmlXPathParserContextPtr ctxt, int nargs) // {{{
{
    xsltTransformContextPtr tctxt;
    xmlChar *str = NULL, *rxp = NULL;
    xmlDocPtr container;
    xmlXPathObjectPtr ret = NULL;

    if ((nargs < 2) || (nargs > 3)) {
        xmlXPathSetArityError(ctxt);
        return;
    }

    int flags;
    if (nargs == 3) {
        xmlChar *tmp = xmlXPathPopString(ctxt);
        if ( (xmlXPathCheckError(ctxt))||(!tmp) ) {
           return;
        }
        flags = parse_flags((const char *)tmp);
        if (flags < 0) {
            xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                "regexp:match : unknown flag given (only 'gi' are supported)\n");
            xmlFree(tmp);
            return;
        }
        xmlFree(tmp);
    } else {
        flags = FLAG_NONE;
    }

    rxp = xmlXPathPopString(ctxt);
    if ( (xmlXPathCheckError(ctxt))||(!rxp) ) {
        return;
    }

    str = xmlXPathPopString(ctxt);
    if ( (xmlXPathCheckError(ctxt))||(!str) ) {
        xmlFree(rxp);
        return;
    }

    /* Return a result tree fragment */
    tctxt = xsltXPathGetTransformContext(ctxt);
    if (tctxt == NULL) {
        xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
            "regexp:match : internal error tctxt == NULL\n");
        goto fail;
    }

    container = xsltCreateRVT(tctxt);
    if (container != NULL) {
        xsltRegisterLocalRVT(tctxt, container);
        ret = xmlXPathNewNodeSet(NULL);
        if (ret != NULL) {
            regexp_match(ctxt, str, rxp, flags, container, ret->nodesetval);
        }
    }

fail:
    xmlFree(str);
    xmlFree(rxp);
    if (ret != NULL)
        valuePush(ctxt, ret);
    else
        valuePush(ctxt, xmlXPathNewNodeSet(NULL));
}
// }}}

// TODO...
// string regexp:replace(string input, string regexp, string flags, string replacement)

/**
 * thobiRegexpSplitFunction:
 * @ctxt: an XPath parser context
 * @nargs: the number of arguments
 *
 * object regexp:split(string input, string regexp, string? flags)
 *
 * Splits up the input on regexp and returns a node set of text nodes
 * separated by <match no="1">...</match> elements, when there are
 * captures present, or a single empty <match/> otherwise.
 */
static void
thobiRegexpSplitFunction(xmlXPathParserContextPtr ctxt, int nargs) // {{{
{
    xsltTransformContextPtr tctxt;
    xmlChar *str = NULL, *rxp = NULL;
    xmlDocPtr container;
    xmlXPathObjectPtr ret = NULL;

    if ((nargs < 2) || (nargs > 3)) {
        xmlXPathSetArityError(ctxt);
        return;
    }

    int flags;
    if (nargs == 3) {
        xmlChar *tmp = xmlXPathPopString(ctxt);
        if ( (xmlXPathCheckError(ctxt))||(!tmp) ) {
           return;
        }
        flags = parse_flags((const char *)tmp);
        if (flags < 0) {
            xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                "regexp:split : unknown flag given (only 'gi' are supported)\n");
            xmlFree(tmp);
            return;
        }
        xmlFree(tmp);
    } else {
        flags = FLAG_NONE;
    }

    rxp = xmlXPathPopString(ctxt);
    if ( (xmlXPathCheckError(ctxt))||(!rxp) ) {
        return;
    }

    str = xmlXPathPopString(ctxt);
    if ( (xmlXPathCheckError(ctxt))||(!str) ) {
        xmlFree(rxp);
        return;
    }

    /* Return a result tree fragment */
    tctxt = xsltXPathGetTransformContext(ctxt);
    if (tctxt == NULL) {
        xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
            "regexp:split : internal error tctxt == NULL\n");
        goto fail;
    }

    container = xsltCreateRVT(tctxt);
    if (container != NULL) {
        xsltRegisterLocalRVT(tctxt, container);
        ret = xmlXPathNewNodeSet(NULL);
        if (ret != NULL) {
            regexp_split(ctxt, str, rxp, flags, container, ret->nodesetval);
        }
    }

fail:
    xmlFree(str);
    xmlFree(rxp);
    if (ret != NULL)
        valuePush(ctxt, ret);
    else
        valuePush(ctxt, xmlXPathNewNodeSet(NULL));
}
// }}}

int load_regexp()
{
   xsltRegisterExtModuleFunction((const xmlChar *)"test",(const xmlChar *)"http://exslt.org/regexp",thobiRegexpTestFunction);
   xsltRegisterExtModuleFunction((const xmlChar *)"match",(const xmlChar *)"http://exslt.org/regexp",thobiRegexpMatchFunction);
//   xsltRegisterExtModuleFunction((const xmlChar *)"replace",(const xmlChar *)"http://exslt.org/regexp",thobiRegexpReplaceFunction);

   xsltRegisterExtModuleFunction((const xmlChar *)"split",(const xmlChar *)"http://exslt.org/regexp",thobiRegexpSplitFunction);
   return 1;
}

#ifdef STANDALONE
int exslt_org_regexp_init()
{
  return load_regexp();
}
#endif

