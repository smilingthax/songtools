/* Copyright by Tobias Hoffmann, Licence: LGPL/MIT, see COPYING
 * This file may, by your choice, be licensed under LGPL or by the MIT license */
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include <string.h>  // memcpy
#include "json.h"
#include <assert.h>

enum json_type {
  JSON_OBJECT,
  JSON_ARRAY,
  JSON_STRING,
  JSON_NUMBER,
  JSON_BOOL,
  JSON_NULL
};

struct json_parse_ctx {
  const xmlChar *cur;

  xmlNodePtr (*build_fn)(enum json_type, const xmlChar *, const xmlChar *, int, xmlNodePtr);
  xmlNodePtr dst;
};

static int _parse_null(struct json_parse_ctx *ctx, xmlNodePtr dst, const xmlChar *key) // {{{
{
  // assert(*ctx->cur == 'n');
  if (xmlStrncmp(ctx->cur + 1, (const xmlChar *)"ull", 3) != 0) {
    return 1;  // bad keyword
  }

  if (!ctx->build_fn(JSON_NULL, key, NULL, 0, dst)) {
    return 2;  // buildfn failed
  }

  ctx->cur += 4;
  return 0;
}
// }}}

static int _parse_bool(struct json_parse_ctx *ctx, xmlNodePtr dst, const xmlChar *key, int value) // {{{
{
  const xmlChar *expect;
  int len;
  if (value) {
    expect = (const xmlChar *)"true";
    len = 4;
  } else {
    expect = (const xmlChar *)"false";
    len = 5;
  }

  // assert(*ctx->cur == *expect);
  if (xmlStrncmp(ctx->cur + 1, expect + 1, len - 1) != 0) {
    return 1;  // bad keyword
  }

  if (!ctx->build_fn(JSON_BOOL, key, expect, len, dst)) {
    return 2;  // buildfn failed
  }

  ctx->cur += len;
  return 0;
}
// }}}

static int unhex(int ch) // {{{ or -1
{
  if (ch >= '0' && ch <= '9') {
    return ch - '0';
  }
  ch |= 0x20;
  if (ch >= 'a' && ch <= 'f') {
    return ch - 'a' + 10;
  }
  return -1;
}
// }}}

static int _read_hex4(const xmlChar *str) // {{{ or -1
{
  // assert(str);
  int ret = unhex(*str);
  for (int i = 1; i < 4 && ret >= 0; i++) {
    ret = (unsigned int)(ret << 4) | (unsigned int)unhex(*++str);
  }
  return ret;
}
// }}}

static int _is_surrogate(unsigned int cp) // {{{
{
  return (cp >= 0xd800 && cp <= 0xdfff);
}
// }}}

static int utf8_enclen(unsigned int cp) // {{{
{
  if (cp <= 0x7f) {
    return 1;
  } else if (cp <= 0x7ff) {
    return 2;
  } else if (cp <= 0xffff) {
    return 3;
  } else if (cp <= 0x10ffff) {
    return 4;
  }
  assert(0);
  return -1;
}
// }}}

static xmlChar *utf8_put(xmlChar *dst, unsigned int ch, signed char len) // {{{
{
  switch (len) {
  case 1:
    *dst = ch;
    break;

  case 2:
    *dst++ = 0xc0 | (ch >> 6);
    *dst = 0x80 | (ch & 0x3f);
    break;

  case 3:
    *dst++ = 0xe0 | (ch >> 12);
    *dst++ = 0x80 | ((ch >> 6) & 0x3f);
    *dst = 0x80 | (ch & 0x3f);
    break;

  case 4:
    *dst++ = 0xf0 | (ch >> 18);
    *dst++ = 0x80 | ((ch >> 12) & 0x3f);
    *dst++ = 0x80 | ((ch >> 6) & 0x3f);
    *dst = 0x80 | (ch & 0x3f);
    break;

  default:
    assert(0);
    return NULL;
  }
  return dst;
}
// }}}

// ret_ulen (unescaped length) is optional
static int _parse_string_hlp(const xmlChar *str, int *ret_ulen) // returns length of escaped section, or -1  // {{{
{
  // assert(str);
  const xmlChar *tmp = str;
  int ulen = 0, res;

  while (1) {
    const xmlChar ch = *tmp;
    switch (ch) {
    case 0:
      return -1;   // early end

    case '\\':
      tmp++;
      switch (*tmp) {
      case 'b': case 'f': case 'n': case 'r': case 't':
      case '"': case '\\': case '/':
        tmp++;
        ulen--;
        break;
      case 'u':
        tmp++;
        res = _read_hex4(tmp);
        if (res < 0 || res == 0 || _is_surrogate(res)) { // FIXME... surrogate problem (-> disallow all encoded surrogates?)  // \u0000 is bad in xml
          return -1;  // bad escape  / not supported
        }
        tmp += 4;
        ulen += utf8_enclen(res) - 6;
        break;
      default:
        return -1;  // bad escape
      }
      break;

    case '"': // regular end
      ulen += tmp - str;
//      assert(ulen >= len);  // (NOTE: escaped string is ALWAYS longer than input ...)
      if (ret_ulen) {
        *ret_ulen = ulen;
      }
      return tmp - str;

    default:  // NOTE: includes utf8 parts
      if (ch <= 0x1f) {
        return -1;  // raw ctrl char not allowed
      }
      tmp++;
      break;
    }
  }
}
// }}}

  // FIXME: does not combine escaped surrogates ...
// CAVE: expects ulen to be big enough, does not validate escape sequences (can even crash!)
static xmlChar *_unescape_string(const xmlChar *str, const xmlChar *end, int ulen) // {{{
{
  xmlChar *ret = xmlMalloc(ulen + 1);
  if (!ret) {
    return NULL;
  }

  int res;
  xmlChar *tmp = ret;
  for (; str != end; ++str) {
    if (*str == '\\') {
      ++str;
      switch (*tmp) {
      case 'b': *tmp++ = '\b'; break;
      case 'f': *tmp++ = '\f'; break;
      case 'n': *tmp++ = '\n'; break;
      case 'r': *tmp++ = '\r'; break;
      case 't': *tmp++ = '\t'; break;
      case 'u':
        res = _read_hex4(str + 1);
        tmp = utf8_put(tmp, res, utf8_enclen(res));
//assert(tmp);
        str += 4;
        break;
      default: *tmp++ = *str; break;
      }
    } else {
      *tmp++ = *str;
    }
  }
  *tmp = 0;

  return ret;
}
// }}}

// TODO? return error position from _parse_string_hlp() via -badpos ?
static int _parse_string(struct json_parse_ctx *ctx, xmlNodePtr dst, const xmlChar *key) // {{{
{
  // assert(*ctx->cur == '"');
  ctx->cur++;

  int ulen;
  const int len = _parse_string_hlp(ctx->cur, &ulen);
  if (len < 0) {
    return 1;  // bad string... (TODO? pos ?)
  }

  xmlNodePtr node;
  if (len != ulen) {
    xmlChar *unescaped = _unescape_string(ctx->cur, ctx->cur + len, ulen);
    if (!unescaped) {
      return 2;  // malloc error
    }
    node = ctx->build_fn(JSON_STRING, key, unescaped, ulen, dst);
    xmlFree(unescaped);
  } else {
    node = ctx->build_fn(JSON_STRING, key, ctx->cur, len, dst);
  }

  if (!node) {
    return 2;  // buildfn failed
  }

  ctx->cur += len + 1;
  return 0;
}
// }}}

static int _is_digit(unsigned char ch) // {{{
{
  return (ch >= '0' && ch <= '9');
}
// }}}

static int _parse_number(struct json_parse_ctx *ctx, xmlNodePtr dst, const xmlChar *key) // {{{
{
  const xmlChar *tmp = ctx->cur;
  if (*tmp == '-') {
    tmp++;
  }

  if (*tmp == '0') {
    tmp++;
  } else if (_is_digit(*tmp)) {
    tmp++;
    while (_is_digit(*tmp)) {
      tmp++;
    }
  } else {
    return 3;  // bad number
  }

  if (*tmp == '.') {
    tmp++;
    if (!_is_digit(*tmp)) {
      return 3;  // bad number
    }
    tmp++;
    while (_is_digit(*tmp)) {
      tmp++;
    }
  }

  if ((*tmp | 0x20) == 'e') {
    tmp++;
    if (*tmp == '+' || *tmp == '-') {
      tmp++;
    }

    if (!_is_digit(*tmp)) {
      return 3;  // bad number
    }
    tmp++;
    while (_is_digit(*tmp)) {
      tmp++;
    }
  }

  if (!ctx->build_fn(JSON_NUMBER, key, ctx->cur, tmp - ctx->cur, dst)) {
    return 2;  // buildfn failed
  }

  ctx->cur = tmp;
  return 0;
}
// }}}

static int _is_ws(unsigned char ch) // {{{
{
  return (ch == '\t' || ch == '\r' || ch == '\n' || ch == ' ');
}
// }}}

static void _skip_ws(struct json_parse_ctx *ctx) // {{{
{
  while (_is_ws(*ctx->cur)) {
    ctx->cur++;
  }
}
// }}}

static int _parse_key(struct json_parse_ctx *ctx, char allow_delim, xmlChar **ret_key) // {{{
{
  // assert(ret_key && !*ret_key);

  _skip_ws(ctx);
  if (*ctx->cur != '"') {
    if (*ctx->cur == allow_delim) {
      *ret_key = NULL;
      return 0;
    }
    return 1;  // unexpected char
  }
  ctx->cur++;

  int ulen;
  const int len = _parse_string_hlp(ctx->cur, &ulen);
  if (len < 0) {
    return 1;  // bad string... (TODO? pos ?)
  }

  const xmlChar *start = ctx->cur;

  ctx->cur += len + 1;
  _skip_ws(ctx);
  if (*ctx->cur != ':') {
    return 1;  // unexpected char
  }
  ctx->cur++;

  if (len != ulen) {
    *ret_key = _unescape_string(start, start + len, ulen);
    if (!*ret_key) {
      return 2;  // malloc error
    }

  } else {
    *ret_key = xmlStrndup(start, len);
    if (!*ret_key) {
      return 2;  // malloc error
    }
  }

  return 0;
}
// }}}

static int _parse_value(struct json_parse_ctx *ctx, xmlNodePtr dst, const xmlChar *key, char allow_delim);

static int _parse_array(struct json_parse_ctx *ctx, xmlNodePtr dst, const xmlChar *key) // {{{
{
  ctx->cur++;

  xmlNodePtr node = ctx->build_fn(JSON_ARRAY, key, NULL, 0, dst);
  if (!node) {
    return 2;  // buildfn failed
  }

  int res = _parse_value(ctx, node, NULL, ']');
  if (res) {
    return res;
  }

  while (1) {
    _skip_ws(ctx);
    if (*ctx->cur != ',') {
      break;
    }
    ctx->cur++;

    int res = _parse_value(ctx, node, NULL, 0);
    if (res) {
      return res;
    }
  }

  if (*ctx->cur != ']') {
    return 1;  // unexpected char
  }
  ctx->cur++;

  return 0;
}
// }}}

static int _parse_object(struct json_parse_ctx *ctx, xmlNodePtr dst, const xmlChar *key) // {{{
{
  ctx->cur++;

  xmlNodePtr node = ctx->build_fn(JSON_OBJECT, key, NULL, 0, dst);
  if (!node) {
    return 2;  // buildfn failed
  }

  int res;
  xmlChar *subkey = NULL;

  res = _parse_key(ctx, '}', &subkey);
  if (res) {
    // assert(!subkey);
    return res;
  }

  if (subkey) {
    while (1) {
      res = _parse_value(ctx, node, subkey, 0);
      xmlFree(subkey);
      subkey = NULL;
      if (res) {
        return res;
      }

      _skip_ws(ctx);
      if (*ctx->cur != ',') {
        if (*ctx->cur != '}') {
          return 1;  // unexpected char
        }
        break;
      }
      ctx->cur++;

      res = _parse_key(ctx, 0, &subkey);
      if (res) {
        // assert(!subkey);
        return res;
      }
    }
  } // else assert(*ctr->cur == '}');

  ctx->cur++;
  return 0;
}
// }}}

static int _parse_value(struct json_parse_ctx *ctx, xmlNodePtr dst, const xmlChar *key, char allow_delim) // {{{
{
  // assert(ctx && ctx->cur);
  while (1) {
    switch (*ctx->cur) {
    case 0: return 1;  // value required, but got EOF

    case 'n': return _parse_null(ctx, dst, key);
    case 't': return _parse_bool(ctx, dst, key, 1);
    case 'f': return _parse_bool(ctx, dst, key, 0);
    case '"': return _parse_string(ctx, dst, key);

    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9': case '-':
      return _parse_number(ctx, dst, key);

    case '[': return _parse_array(ctx, dst, key);
    case '{': return _parse_object(ctx, dst, key);

    case '\t': case '\r': case '\n': case ' ':
      ctx->cur++;
      _skip_ws(ctx);
      break; // (continue loop)

    default:
      if (*ctx->cur == allow_delim) {
        return 0;
      }
      return 1;  // unexpected char
    }
  }
}
// }}}

static int parse_json(const xmlChar *str, xmlNodePtr (*build_fn)(enum json_type, const xmlChar *, const xmlChar *, int, xmlNodePtr), xmlDocPtr doc) // {{{
{
  assert(str && build_fn && doc);

  if (str[0] == 0xef && str[1] == 0xbb && str[2] == 0xbf) {  // UTF-8 BOM  (we don't support anything else!)
    str += 3;
  }

  struct json_parse_ctx ctx = {
    .cur = str,
    .build_fn = build_fn,
  };

  int ret = _parse_value(&ctx, (xmlNodePtr)doc, NULL, 0);
  if (ret) {
    return ctx.cur - str + 1;
  }
  _skip_ws(&ctx);

  if (*ctx.cur) {
    return ctx.cur - str + 1;
  }

  return 0;
}
// }}}

static const char *nodename_for_type(enum json_type type) // {{{
{
  switch (type) {
  case JSON_OBJECT: return "map";
  case JSON_ARRAY: return "array";
  case JSON_STRING: return "string";
  case JSON_NUMBER: return "number";
  case JSON_BOOL: return "boolean";
  case JSON_NULL: return "null";
  default:
    assert(0);
    return NULL;
  }
}
// }}}

static xmlNodePtr json_build_xml(enum json_type type, const xmlChar *key, const xmlChar *value, int vlen, xmlNodePtr dst) // {{{
{
  const xmlChar *tag = (const xmlChar *)nodename_for_type(type);
  if (!tag) {
    return NULL;
  }

  xmlNodePtr node;
  if (dst->type == XML_DOCUMENT_NODE) { // top level / very first call
    // (assert((xmlDocPtr)dst == dst->doc); ...)
    if (!dst->doc->dict) {
      dst->doc->dict = xmlDictCreate();
    }

    node = xmlNewDocNode(dst->doc, NULL, tag, NULL);
    if (!node) {
      return NULL;
    }

    node->ns = xmlNewNs(node, (const xmlChar *)"http://www.w3.org/2005/xpath-functions", NULL);
    if (!node->ns) {
      return NULL;
    }

  } else {
    node = xmlNewDocNode(dst->doc, dst->ns, tag, NULL);
    if (!node) {
      return NULL;
    }
  }

  if (key) {
    xmlSetProp(node, (const xmlChar *)"key", key);
  }

  if (value) {
    // assert(type != JSON_NULL);
    xmlNodePtr text = xmlNewDocTextLen(dst->doc, value, vlen);  // this esp. allows vlen
    xmlAddChild(node, text);
  }

  return xmlAddChild(dst, node); // (could theoretically be merged ...)
}
// }}}

/**
 * thobiJsonToXmlFunction:
 * @ctxt: an XPath parser context
 * @nargs: the number of arguments
 *
 * node-set json:json-to-xml(string json)
 *
 * Parses json string into a xmlns http://www.w3.org/2005/xpath-functions
 * representation: <map> / <array> / <number> / <string> / <boolean> / <null>
 * potentially having @key.
 *
 * Compared to the XSLT 3.0 implementation, an optional options parameter
 * is not supported.
 * The result corresponds to { liberal=false, validate=false, escape=false, no fallback }.
 */
static void
thobiJsonToXmlFunction(xmlXPathParserContextPtr ctxt, int nargs)
{
    xsltTransformContextPtr tctxt;
    xmlChar *str;
    xmlDocPtr container;
    xmlXPathObjectPtr ret = NULL;

    if (nargs != 1) {
      xmlXPathSetArityError(ctxt);
      return;
    }

    str = xmlXPathPopString(ctxt);
    if (xmlXPathCheckError(ctxt) || (str == NULL)) {
      return;
    }

    /* Return a result tree fragment */
    tctxt = xsltXPathGetTransformContext(ctxt);
    if (tctxt == NULL) {
      xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                         "thobi:json-to-xml : internal error tctxt == NULL\n");
      goto fail;
    }

    container = xsltCreateRVT(tctxt);
    if (container == NULL) {
      goto fail;
    }

    xsltRegisterLocalRVT(tctxt, container);
    ret = xmlXPathNewNodeSet(NULL);
    if (ret == NULL) {
      goto fail;
    }

    int res = parse_json(str, json_build_xml, container);
    if (res != 0) {
      const int len = xmlStrlen(str);
      xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL,
                         "thobi:json-to-xml : could not parse json at: '%.*s%s'\n", 20, str + res - 1, (len - res + 1 > 20 ? "..." : ""));
      goto fail;
    }

    xmlXPathNodeSetAddUnique(ret->nodesetval, (xmlNodePtr)container);

fail:
    xmlFree(str);
    if (ret != NULL)
        valuePush(ctxt, ret);
    else
        valuePush(ctxt, xmlXPathNewNodeSet(NULL));
}

//#define ESCAPE_HIGHCTRL
#define ESCAPE_NONBMP

static int _escaped_length(const xmlChar *str) // {{{  -1 on invalid utf8
{
  int len = 0;
  while (1) {
    const unsigned char ch = *str;
    switch (ch) {
    case 0:
      return len;

    case 8: case 9:
    case 10: case 12: case 13:
    case '"': case '\\':
      str++;
      len += 2;
      break;

    default:
      if (ch > 0x80) {
#if defined(ESCAPE_HIGHCTRL) || defined(ESCAPE_NONBMP)
        int clen = 4;
        const int cp = xmlGetUTF8Char(str, &clen);
        if (cp < 0) {
          return -1;
        }

        str += clen;
#ifdef ESCAPE_HIGHCTRL
        if (cp >= 0x7f && cp < 0xa0) {
          len += 6;
        } else
#endif
#ifdef ESCAPE_NONBMP
        if (cp > 0xffff) {
          len += 12;
        } else
#endif
        {
          len += clen;
        }

#else
        const int clen = xmlUTF8Size(str);
        if (clen < 0) {
          return -1;
        }
        str += clen;
        len += clen;
#endif

      } else {
        str++;
        len++;
      }
      break;
    }
  }
}
// }}}

#if defined(ESCAPE_HIGHCTRL) || defined(ESCAPE_NONBMP)
static xmlChar *_hexesc(xmlChar *dst, unsigned int cp) // {{{ only for cp <= 0xffff
{
  // assert(cp <= 0xffff);
  static const unsigned char hex[] = "0123456789abcdef";
  *dst++ = '\\';
  *dst++ = 'u';
  *dst++ = hex[(cp >> 12) & 0x0f];
  *dst++ = hex[(cp >> 8) & 0x0f];
  *dst++ = hex[(cp >> 4) & 0x0f];
  *dst++ = hex[cp & 0x0f];
  return dst;
}
// }}}
#endif

// CAVE: expects elen to be big enough, does not validate utf8
static xmlChar *_escape_string(const xmlChar *str, int elen) // {{{
{
  xmlChar *ret = xmlMalloc(elen + 1);
  if (!ret) {
    return NULL;
  }

  xmlChar *tmp = ret;
  while (1) {
    const unsigned char ch = *str;
    switch (ch) {
    case 0:
      *tmp = 0;
      return ret;

    case 8: str++; *tmp++ = '\\'; *tmp++ = 'b'; break;
    case 9: str++; *tmp++ = '\\'; *tmp++ = 't'; break;
    case 10: str++; *tmp++ = '\\'; *tmp++ = 'n'; break;
    case 12: str++; *tmp++ = '\\'; *tmp++ = 'f'; break;
    case 13: str++; *tmp++ = '\\'; *tmp++ = 'r'; break;
    case '"': case '\\':
      str++;
      *tmp++ = '\\';
      *tmp++ = ch;
      break;

    default:
      if (ch > 0x80) {
#if defined(ESCAPE_HIGHCTRL) || defined(ESCAPE_NONBMP)
        int clen = 4;
        int cp = xmlGetUTF8Char(str, &clen);
        if (cp < 0) {
          return NULL;
        }

#ifdef ESCAPE_HIGHCTRL
        if (cp >= 0x7f && cp < 0xa0) {
          tmp = _hexesc(tmp, cp);
        } else
#endif
#ifdef ESCAPE_NONBMP
        if (cp > 0xffff) { // convert to escaped surrogate pair
          cp -= 0x10000;
          tmp = _hexesc(tmp, 0xd800 | (cp >> 10));
          tmp = _hexesc(tmp, 0xdc00 | (cp & 0x03ff));
        } else
#endif
        {
          memcpy(tmp, str, clen);
          tmp += clen;
        }
        str += clen;

#else
        const int clen = xmlUTF8Size(str);
        if (clen < 0) {
          return NULL;
        }
        memcpy(tmp, str, clen);
        str += clen;
        tmp += clen;
#endif

      } else {
        str++;
        *tmp++ = ch;
      }
      break;
    }
  }
}
// }}}

/**
 * thobiEscapeFunction:
 * @ctxt: an XPath parser context
 * @nargs: the number of arguments
 *
 * string json:escape(string str)
 *
 * Returns the string as JSON-escaped string (just the inner part).
 */
static void
thobiEscapeFunction(xmlXPathParserContextPtr ctxt, int nargs) // {{{
{
    xmlChar *str;

    if (nargs != 1) {
      xmlXPathSetArityError(ctxt);
      return;
    }

    str = xmlXPathPopString(ctxt);
    if (xmlXPathCheckError(ctxt) || (str == NULL)) {
      return;
    }

    const int len = _escaped_length(str);
    if (len <= 0) {
      if (len < 0) {
        xsltGenericError(xsltGenericErrorContext,
                         "json:escape : invalid UTF-8\n");
      }
      xmlXPathReturnEmptyString(ctxt);
      xmlFree(str);
      return;
    }

    xmlChar *ret = _escape_string(str, len);
    if (!ret) { // (esp. malloc failed)
      xmlFree(str);
      return;
    }

    xmlFree(str);
    xmlXPathReturnString(ctxt, ret);  // eats
}
// }}}

int load_json()
{
   xsltRegisterExtModuleFunction((const xmlChar *)"json-to-xml",(const xmlChar *)"thax.home/json",thobiJsonToXmlFunction);
//   xsltRegisterExtModuleFunction((const xmlChar *)"xml-to-json",(const xmlChar *)"thax.home/json",thobiXmlToJsonFunction);
   xsltRegisterExtModuleFunction((const xmlChar *)"escape",(const xmlChar *)"thax.home/json",thobiEscapeFunction);

   return 1;
}

#ifdef STANDALONE
int thax_home_json_init()
{
  return load_json();
}
#endif
