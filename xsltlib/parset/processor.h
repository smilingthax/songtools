#ifndef _PROCESSOR_H
#define _PROCESSOR_H

#include <libxml/xmlmemory.h>
#include <libxml/xpath.h>
#include <vector>

// abstract interface for TreeTraversal
class TreeTraverse {
public:
  virtual ~TreeTraverse() {}
  virtual void openNode(const xmlChar *name)=0;
  virtual void closeNode(const xmlChar *name)=0;
  virtual void text(const xmlChar *text)=0;
  virtual void attrib(const xmlChar *name,const xmlChar *value)=0;
  virtual void comment(const xmlChar *text)=0;
};

class TreeBuilder : public TreeTraverse {
public:
  TreeBuilder(xmlDocPtr doc,xmlXPathObjectPtr nodeset=NULL,xmlChar *debug=NULL,xmlXPathParserContextPtr ctxt=NULL);
  virtual ~TreeBuilder();

  void openNode(const xmlChar *name);
  void closeNode(const xmlChar *name);
  void text(const xmlChar *text);
  void attrib(const xmlChar *name,const xmlChar *value);
  void comment(const xmlChar *text);
  void attrib(const xmlChar *name,int value);

  void error(const char *fmt,...);
  bool has_error();
private:
  xmlDocPtr doc;
  xmlXPathObjectPtr nodeset;
  xmlChar *debug;
  xmlXPathParserContextPtr ctxt;
  xmlNodePtr node;
  bool err;
};

// our custom processor stuff
class ProcNodeBufferItem {
public:
  bool is_element() const;
  bool is_element_open() const;
  bool is_element_close() const;
  bool is_text() const;
  bool is_attrib() const;
  bool is_comment() const;
  bool is_br() const;
  bool is_spacer() const;
  bool is_akk() const;

  bool is_whitespace(bool nl_as_WS=false) const;  // only for text

  xmlChar *name,*value;

  // special variables
  int no,brk;
  bool unclosed_empty;  // if a tag should be empty, this is flagged until it is closed (ATTENTION: only for single-item tags)
  ProcNodeBufferItem *attrqueue,*attrlast;
 
  // "have to be public..."
  ProcNodeBufferItem();
  ProcNodeBufferItem(const xmlChar *name,const xmlChar *value=NULL); // does strdup, does not: type
  ~ProcNodeBufferItem();
  void set_name(const xmlChar *_name);
  void set_value(const xmlChar *_value);

  enum { NODE_NONE, NODE_ELEM, NODE_ELEM_END, NODE_TEXT, NODE_ATTRIB,
         NODE_BR, NODE_SPACER, NODE_AKK } type;
  void build(TreeBuilder &tb) const;
  ProcNodeBufferItem *prev,*next;
};

class procTool;
class ProcTraverse : public TreeTraverse {
public:
  ProcTraverse(TreeBuilder &tb);
  virtual ~ProcTraverse();

  void openNode(const xmlChar *name);
  void closeNode(const xmlChar *name);
  void text(const xmlChar *text);
  void attrib(const xmlChar *name,const xmlChar *value);
  void comment(const xmlChar *text);

  // moves nodes: [start;end] behind after  // after==NULL -> at start of list, end==NULL -> everything till end of list
  void move(ProcNodeBufferItem *after,ProcNodeBufferItem *start,ProcNodeBufferItem *end=NULL);
  bool in_list(ProcNodeBufferItem *item,ProcNodeBufferItem *start,ProcNodeBufferItem *end) const; // item==NULL -> false
  void push(ProcNodeBufferItem *item);
  void pop();
  void flush();
//  ProcNodeBufferItem *operator[](int index);

  enum Tagname { BLOCK_TAG, BR_TAG, BF_TAG, SPACER_TAG, AKK_TAG, COMMENT_TAG,
                 XLANG_TAG,
                 UNKNOWN_TAG, NO_TAG=UNKNOWN_TAG };
  bool is_blocktag(const xmlChar *name);
  Tagname tag(const xmlChar *name);
private:
  TreeBuilder &tb;
  typedef std::vector<const ProcNodeBufferItem *> NodeStack;
  NodeStack ns;
  ProcNodeBufferItem *queue,*last;
  typedef std::vector<procTool *> ProcTools;
  ProcTools tools;

  friend class normalizeBrTool;
  friend class substXlangTool;
};

// abstract interface for processingTools
class procTool {
public:
  procTool(ProcTraverse &parent) : parent(parent) {}
  virtual ~procTool() {}
  virtual void openItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item) {}
  virtual void closeItem(ProcTraverse::Tagname tag,ProcNodeBufferItem *&item,ProcNodeBufferItem *last) {}
  virtual void textItem(ProcNodeBufferItem *&item,ProcNodeBufferItem *last) {}
  // return <0 if invalid, >0 if consumed, 0 if untouched
  virtual int attribItem(ProcNodeBufferItem *item,const xmlChar *name,const xmlChar *value) { return 0; } 
  virtual void commentItem(ProcNodeBufferItem *&item) {}
protected:
  ProcTraverse &parent;
};

// helper
// what is a whitespace?
inline bool iswhite(char c)
{
  return ( (c==' ')||(c=='\t') );
}
inline bool iswhitenl(char c)
{
  return ( (c==' ')||(c=='\t')||(c=='\r')||(c=='\n') );
}
bool iswhitespace(const xmlChar *str,bool nl_as_WS=false);
bool get_int_attr(int &to,const char *attrname,const xmlChar *name,const xmlChar *value);

#endif
