/* Copyright by Tobias Hoffmann, Licence: LGPL/MIT, see COPYING
 * This file may, by your choice, be licensed under LGPL or by the MIT license */
#include <libxml/xpathInternals.h>
#include <libxslt/xsltutils.h>
#include <libxslt/extensions.h>
#include <string.h>
#include <assert.h>
#include "akker.h"

// lang can be NULL
static int find_vowel(const unsigned char *str,const char *lang) // {{{
{
  // TODO more...
  for (int iA=0;str[iA];iA++) {
    const unsigned char c=str[iA]|0x20;
    const unsigned char d=str[iA+1]|0x20;
    if (  (c=='a')||
          (c=='e')||
          (c=='i')||
          (c=='o')||
          ( (c=='u')&&((iA==0)||((str[iA-1]|0x20)!='q')) )||
          ( (str[iA]==0xc3)&&( (d==0xa4)||(d==0xb6)||(d==0xbc) ) )  ) { // ä ö ü
      return iA;
    }
  }
  if ( (lang)&&(lang[0]=='e')&&(lang[1]=='n')&&(!lang[2]) ) {
    for (int iA=0;str[iA];iA++) {
      const unsigned char c=str[iA]|0x20;
      if (c=='y') {
        return iA;
      }
    }
  }
  return -1;
}
// }}}

typedef struct {
  xmlXPathParserContextPtr ctxt;
  xmlDocPtr doc;

  xmlNodeSetPtr nodes;
  xmlChar *lang; // or null

  // state
  xmlNodePtr buildParent;

  char vowelState; // 0: No vowel needed, 1: vowel needed, no text seen, 2: vowel needed, text seen (possible vowel candidate: see below)
                   // -1: only create <akk/> at word start
  // NOTE: we have to keep looking until we reach a word start
  xmlNodePtr vowelCandidateText; // an output(!) text node
  int vowelCandidatePos;

  char wordState;  // 0: No tracking, 1: fixup nextChord/@fill (if not word-start)
  const xmlChar *nextText; // the (logically) following (input!) text (for determining word-end boundary). could be NULL: no active word follows
  xmlNodePtr nextChord;

} AkkerCtxt;

static xmlNodePtr prependChild(xmlNodePtr parent, xmlNodePtr elem) // {{{
{
    assert(parent);
    if (parent->children) {
        return xmlAddPrevSibling(parent->children, elem);
    } else {
        return xmlAddChild(parent, elem);
    }
}
// }}}

#define transformError(ctxt, ...) \
    xsltTransformError(xsltXPathGetTransformContext(ctxt), NULL, NULL, "akk:akker : " __VA_ARGS__)

static int hasError(xmlXPathParserContextPtr ctxt) // {{{
{
    xsltTransformContextPtr tctxt = xsltXPathGetTransformContext(ctxt);
    return (!tctxt)||(tctxt->state != XSLT_STATE_OK);
}
// }}}


static int is_word_end(const xmlChar *text) // {{{
{
    if (!text)  {
        return 1;
    }
    unsigned char c = *text;
    assert(c);
    return (c==' ');
}
// }}}

static void split_wrap_vowel(AkkerCtxt *actxt) // {{{
{
    assert(actxt->vowelCandidateText);
    const xmlChar *text = actxt->vowelCandidateText->content;
    const int pos = actxt->vowelCandidatePos;
    const int clen = xmlUTF8Size(text+pos);

    // we have to create the non-text element first, otherwise xmlAddNextSibling will merge the texts
    xmlNodePtr wrap = xmlNewDocNode(actxt->doc, NULL, (const xmlChar *)"vow", NULL);
    xmlAddNextSibling(actxt->vowelCandidateText, wrap);

    if (text[pos+clen]) {
        xmlNodePtr newNode = xmlNewDocText(actxt->doc, text+pos+clen);
        xmlAddNextSibling(wrap, newNode);
    }

    if (pos == 0) {
        xmlUnlinkNode(actxt->vowelCandidateText);
        actxt->vowelCandidateText->content[clen] = 0; // only vowel is left
        xmlAddChild(wrap, actxt->vowelCandidateText); // relink as child of vow
    } else {
        xmlChar vowel[9];
        assert( (clen>0)&&(clen<8) );
        memcpy(vowel, text+pos, clen);
        vowel[clen]=0;
        xmlNodeSetContent(wrap, vowel);

        actxt->vowelCandidateText->content[pos] = 0; // terminate first text early
    }
}
// }}}

static void create_vowel_nodes(AkkerCtxt *actxt, const xmlChar *word_start) // {{{
{
    int pos = find_vowel(word_start, (const char *)actxt->lang); // potential first vowel of last word
    if (~pos) { // create nodes splitted
        const int clen = xmlUTF8Size(word_start+pos);
        if (word_start[pos+clen]) {
            xmlNodePtr newNode = xmlNewDocText(actxt->doc, word_start+pos+clen);
            prependChild(actxt->buildParent, newNode);
        }

        // assert(word_start+pos is not an entity reference [vowels are never...]);
        xmlChar vowel[9];
        assert( (clen>0)&&(clen<8) );
        memcpy(vowel, word_start+pos, clen);
        vowel[clen]=0;
        xmlNodePtr wrap = xmlNewDocNode(actxt->doc, NULL, (const xmlChar *)"vow", vowel);
        prependChild(actxt->buildParent, wrap);

        if (pos > 0) {
            xmlNodePtr newNode = xmlNewDocTextLen(actxt->doc, word_start, pos);
            prependChild(actxt->buildParent, newNode);
        }
    } else { // split existing node
        if (!actxt->vowelCandidateText) {
            transformError(actxt->ctxt, "Vowel required, but word is without ?!\n");
            return;
        }
        split_wrap_vowel(actxt);

        if (*word_start) {
            xmlNodePtr newNode = xmlNewDocText(actxt->doc, word_start);
            prependChild(actxt->buildParent, newNode);
        }
    }
}
// }}}

// TODO ...  current idea is to create @fill only in "unexpected cases" ...
static void set_fill(xmlNodePtr akk, unsigned char c) // {{{  - only for initial set, not for overwriting!
{
    assert(akk);
    xmlChar val[2] = { c, 0 };
    if (akk->children) {
        assert( (akk->children->type==XML_TEXT_NODE)&&(*akk->children->content)&&(!akk->children->content[1]) );
        if ( (c == ' ')||(akk->children->content[0] != c) ) {
            xmlSetProp(akk, (const xmlChar *)"fill", val);
        }
    } else {
        if (c == '-') {
            xmlNodeSetContent(akk, val);
        } else if (c != ' ') {  // _
            xmlSetProp(akk, (const xmlChar *)"fill", val);
        }
    }
}
// }}}

static void resolve_word_start(AkkerCtxt *actxt, char is_start) // {{{
{
  if (!is_start) {
    set_fill(actxt->nextChord, '-');
  } else {
    set_fill(actxt->nextChord, ' ');
  }
}
// }}}

static void leave_word(AkkerCtxt *actxt) // {{{
{
    actxt->nextText = NULL;
    if (actxt->wordState) {
        resolve_word_start(actxt, 1);
        actxt->wordState = 0;
    }
}
// }}}

/* Notes:
 * - processing happens in reverse
 * - <akk>s are analyzed but copied verbatim
 * - <akk/> are added at word boundaries where |_ is used without |-
 */

// we don't care about akk's attributes here
static void onAkk(AkkerCtxt *actxt, unsigned char type, xmlNodePtr akk)
{
    if (type == '_') {
        if (actxt->vowelState == 2) { // already requested, but intermediate text seen
            if (!actxt->vowelCandidateText) {
                transformError(actxt->ctxt, "Vowel required, but none found\n");
                return;
            }
// TODO... link vowel with actxt->nextChord ?
            split_wrap_vowel(actxt);
            actxt->vowelCandidateText = NULL;
// TODO? link akk with vowel and actxt->nextChord (as there will be no <akk/>) ?

            assert(!is_word_end(actxt->nextText));
            xmlNodeSetContent(akk, (const xmlChar *)"=");
            assert(actxt->wordState==0); // see Trick, below
            actxt->vowelState = 1;
            return;
        } else if (actxt->vowelState == 1) {
            // TODO? link with following |_ ? (actxt->nextChord...) [and vowel, see above]
            assert(actxt->wordState==0); // see Trick, below
            xmlNodeSetContent(akk, (const xmlChar *)"^");  // optimization
            return; // optimization...
        }
// NOTE: cannot track -1 beyond this point ...
        actxt->vowelState = 1; // even when already in need!

        if (actxt->wordState) { // e.g.  ab|_|cd
            // Trick: we know that |_ is not possible at word start
            resolve_word_start(actxt, 0);
            actxt->wordState = 0;
        }

        if (!is_word_end(actxt->nextText)) {
            xmlNodeSetContent(akk, (const xmlChar *)"^");
        }
        return;
    }

    if (actxt->vowelCandidateText) { // all | implicitly act as |-    // FIXME: special case for  |_  ...
        assert(actxt->vowelState == 2);
// TODO... link vowel with actxt->nextChord ?
        split_wrap_vowel(actxt);
        actxt->vowelCandidateText = NULL;
        actxt->vowelState = 0;
// TODO? link akk with vowel and actxt->nextChord (as there will be no <akk/>) ?
    }
    if (actxt->vowelState > 0) {
        transformError(actxt->ctxt, "Vowel required, but none found\n");
        return;
    }

    if ( (!type)||(type == '-') ) {
        // NOTE:  ab|-|c  (and: "a||b a||-b" is parsed as "a| |b a| |-b", so <akk note="a"/><akk note="b"/> is never in sout.xml ...)
        if (actxt->wordState) {
            assert(!is_word_end(actxt->nextText));
        } else if (!is_word_end(actxt->nextText)) {
            actxt->wordState = 1;
        }

    } else if (type == ' ') {
        leave_word(actxt); // resolves wordState and clears nextText

    } else { // ... or: onAkkOver ? ...
        assert(0); // for now
    }
}

static int onOpen(AkkerCtxt *actxt, xmlNodePtr node)
{
    if (xmlStrcmp(node->name, (const xmlChar *)"akk")==0) {
        xmlNodePtr newNode = xmlDocCopyNode(node, actxt->doc, 1); // copy properties, namespaces *and children*
        prependChild(actxt->buildParent, newNode);

        // we expect at most one child, a text
        if (!node->children) {
            onAkk(actxt, 0, newNode);
            if (hasError(actxt->ctxt)) return 0;
        } else if (node->children == node->last) {
            if ( (node->children->type != XML_TEXT_NODE)||(!node->children->content)||
                 (!*node->children->content)||
                 (node->children->content[1]) ) {
                transformError(actxt->ctxt, "unexpected child of <akk>\n");
                return 0;
            }
            onAkk(actxt, *node->children->content, newNode);
            if (hasError(actxt->ctxt)) return 0;
        } else {
            transformError(actxt->ctxt, "too many childs for <akk>\n");
            return 0;
        }

        actxt->nextChord = newNode;
        // actxt->wordState already set in onAkk

        return 0; // skip subtree

    } else if (node->children) { // non-empty tag
assert(!actxt->vowelState);
        leave_word(actxt); // word will not span across

    } else if (xmlStrcmp(node->name, (const xmlChar *)"br")==0) {
assert(!actxt->vowelState);
        leave_word(actxt); // word will not span across
    }

    return 1; // copy and descend into subtree
}

static void onFinish(AkkerCtxt *actxt); // FIXME?
static void onClose(AkkerCtxt *actxt, xmlNodePtr node, xmlNodePtr newNode)
{
    if (node->children) { // non-empty tag
        // NOTE: ordering (onClose / buildParent change in traverse()) is critical!
        onFinish(actxt);
    }
}

// wordState is 0 after this function (except for empty text)
static int onText(AkkerCtxt *actxt, const xmlChar *text)
{
    assert(*text);
    if (!*text) return 0; // TODO?

    actxt->nextText = text;

    if (actxt->vowelState != 0) {
        const xmlChar *word_start = (const xmlChar *)strrchr((const char *)text, ' ');
        if (!word_start) {
            if (actxt->wordState) {
                resolve_word_start(actxt, 0);
                actxt->wordState = 0;
            }

            if (actxt->vowelState == -1) {
                return 1;
            }
            actxt->vowelState = 2;

            int pos = find_vowel(text, (const char *)actxt->lang); // potential first vowel of last word
            if (~pos) {
                xmlNodePtr newNode = xmlNewDocText(actxt->doc, text);
                prependChild(actxt->buildParent, newNode);

                actxt->vowelCandidateText = newNode;
                actxt->vowelCandidatePos = pos;
                return 0; // we already had to copy
            }

        } else {
            if (actxt->wordState) {
                resolve_word_start(actxt, (!word_start[1]));
                actxt->wordState = 0;
            }

            if (actxt->vowelState != -1) {
                create_vowel_nodes(actxt, word_start+1);
                if (hasError(actxt->ctxt)) return 0;
            }
            actxt->vowelState = 0;

// TODO... link with actxt->nextChord ?
            // add word start indicator <akk/>
            xmlNodePtr akk = xmlNewDocNode(actxt->doc, NULL, (const xmlChar *)"akk", NULL);
            prependChild(actxt->buildParent, akk);
            actxt->nextChord = akk;
            // no set_fill/wordState needed as prev char (i.e. *word_start) is whitespace

            xmlNodePtr newNode = xmlNewDocTextLen(actxt->doc, text, word_start+1-text);
            prependChild(actxt->buildParent, newNode);

            actxt->vowelCandidateText = NULL;
            return 0;
        }
    } else if (actxt->wordState) {
        const int len = xmlStrlen(text);
        resolve_word_start(actxt, (text[len-1]==' '));
        actxt->wordState = 0;
    }

    return 1; // copy unchanged
}

static int onComment(AkkerCtxt *actxt, xmlNodePtr node)
{
    return 1; // copy unchanged
}

static void onFinish(AkkerCtxt *actxt)
{
    leave_word(actxt);

    if (actxt->vowelState != 0) {
        if (actxt->vowelState != -1) {
            if (!actxt->vowelCandidateText) {
                transformError(actxt->ctxt, "Vowel required, but none found\n");
                return;
            }
            split_wrap_vowel(actxt);
            actxt->vowelCandidateText = NULL;
        }
        actxt->vowelState = 0;

// TODO... link with actxt->nextChord ?
        // add word start indicator <akk/>
        xmlNodePtr akk = xmlNewDocNode(actxt->doc, NULL, (const xmlChar *)"akk", NULL);
        prependChild(actxt->buildParent, akk);
        actxt->nextChord = akk;
        // no set_fill/wordState needed: prev char does not exist / is whitespace
    }
}

static void
traverse(AkkerCtxt *actxt, xmlNodePtr node)
{
    if (node->type == XML_ELEMENT_NODE) {
        if (!onOpen(actxt, node)) {
            return; // skip subtree
        }
        xmlNodePtr newNode = xmlDocCopyNode(node, actxt->doc, 2); // copy properties and namespaces, but not children
        prependChild(actxt->buildParent, newNode);

        xmlNodePtr child;
        actxt->buildParent = newNode;
        for (child=node->last; child; child=child->prev) { // reverse
            traverse(actxt, child);
            if (hasError(actxt->ctxt)) return;
        }

        onClose(actxt, node, newNode);
        actxt->buildParent = newNode->parent;
    } else if (node->type == XML_TEXT_NODE) {
        if (onText(actxt, node->content)) {
            xmlNodePtr newNode = xmlNewDocText(actxt->doc, node->content);
            prependChild(actxt->buildParent, newNode);
        }
    } else if (node->type == XML_COMMENT_NODE) {
        if (onComment(actxt, node)) {
            xmlNodePtr newNode = xmlNewDocComment(actxt->doc, node->content);
            prependChild(actxt->buildParent, newNode);
        }
    } else {
//        xmlNodePtr newNode = xmlDocCopyNode(node, actxt->doc, 0);  // ...
        transformError(actxt->ctxt, "unsupported node type %d\n", node->type);
    }
}

static void
doAkker(AkkerCtxt *actxt)
{
    actxt->buildParent = (xmlNodePtr)actxt->doc;

    int i;
    for (i=actxt->nodes->nodeNr-1; i>=0; i--) { // reverse
        traverse(actxt, actxt->nodes->nodeTab[i]);
        if (hasError(actxt->ctxt)) return;
    }
    onFinish(actxt);

//    actxt->buildParent = NULL;
}

/**
 * thobiAkkAkkerFunction:
 * @ctxt: an XPath parser context
 * @nargs: the number of arguments
 *
 * Iterates over the input tree and encloses the first vowel of each word that
 * directly preceeds <akk>_</akk>.
 */
static void
thobiAkkAkkerFunction(xmlXPathParserContextPtr ctxt, int nargs)
{
    xmlXPathObjectPtr ret = NULL;

    AkkerCtxt actxt = { .ctxt = ctxt };

    // fetch args
    if ((nargs < 1) || (nargs > 2)) {
        xmlXPathSetArityError(ctxt);
        return;
    }

    if (nargs == 2) {
        actxt.lang = xmlXPathPopString(ctxt);
        if (xmlXPathCheckError(ctxt)) goto fail;
    }

    actxt.nodes = xmlXPathPopNodeSet(ctxt);
    if (xmlXPathCheckError(ctxt)) goto fail;

    // create result tree fragment
    xsltTransformContextPtr tctxt = xsltXPathGetTransformContext(ctxt);
    if (tctxt == NULL) {
        transformError(ctxt, "internal error tctxt == NULL\n");
        goto fail;
    }
    xmlDocPtr container = xsltCreateRVT(tctxt);
    if (container == NULL) goto fail;

    xsltRegisterLocalRVT(tctxt, container);
    actxt.doc = container;

    // process
    doAkker(&actxt);
    if (tctxt->state == XSLT_STATE_ERROR) {     // - show partial output on error! (for debugging)
        tctxt->state = XSLT_STATE_STOPPED;
    }

    // collect top level into result nodeset
    ret = xmlXPathNewNodeSet(NULL);
    if (ret != NULL) {
        xmlNodePtr node;
        for (node=container->children; node; node=node->next) {
            xmlXPathNodeSetAdd(ret->nodesetval, node);
        }
    }

fail:
    if (actxt.nodes != NULL)
        xmlXPathFreeNodeSet(actxt.nodes);
    if (actxt.lang != NULL)
        xmlFree(actxt.lang);

    if (ret != NULL)
        valuePush(ctxt, ret);
    else
        valuePush(ctxt, xmlXPathNewNodeSet(NULL));
}

int load_akker()
{
   xsltRegisterExtModuleFunction((const xmlChar *)"akker",(const xmlChar *)"thax.home/akk",thobiAkkAkkerFunction);
   return 1;
}

#ifdef STANDALONE
int thax_home_akk_init()
{
  return load_akker();
}
#endif
