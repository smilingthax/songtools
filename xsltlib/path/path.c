/* Copyright by Tobias Hoffmann, Licence: LGPL/MIT, see COPYING
 * This file may, by your choice, be licensed under LGPL or by the MIT license */
//#include <libxslt/extensions.h>
#include <libxml/xmlIO.h>
#include <string.h>
#include "path.h"

//#define DEBUG

#ifdef DEBUG
static int mymatch(const char *filename)
{
  printf("OP: %s\n",filename);
  return 0;
}
#endif

struct _PATH_DATA {
  char *filename; // either >filename or >prefix
  char *prefix;

  char *path; // either >path or >data,>len (>data,>len only with >filename)
  const char *data;
  int len;
};

static struct _PATH_DATA *remaps=NULL;
static int remap_len=0,remap_size=0;
static xmlParserInputBufferCreateFilenameFunc old_handler=NULL;

int ensure_pathdata() // {{{
{
  struct _PATH_DATA *tmp;

  if (remap_len>=remap_size) {
    remap_size+=10*sizeof(struct _PATH_DATA);
    tmp=realloc(remaps,remap_size);
    if (!tmp) {
      return -1;
    }
    remaps=tmp;
  }
  memset(remaps+remap_len,0,sizeof(struct _PATH_DATA));

  return 0;
}
// }}}

void free_pathdata() // {{{
{
  while (remap_len>0) {
    remap_len--;
    free(remaps[remap_len].filename);
    free(remaps[remap_len].prefix);
    free(remaps[remap_len].path);
  }
  free(remaps);
  remap_size=0;
}
// }}}

// static data!
int path_register_static_file(const char *filename,const char *data,int len) // {{{
{
  if (ensure_pathdata()==-1) {
    return -1;
  }
  if ( (!filename)||(!data)||(len<0) ) {
    return -2;
  }
  remaps[remap_len].filename=strdup(filename);
  if (!remaps[remap_len].filename) {
    return -3;
  }
  remaps[remap_len].data=data;
  remaps[remap_len].len=len;
  remap_len++;

  return 0;
}
// }}}

int path_register_remap(const char *filename,const char *path) // {{{
{
  if (ensure_pathdata()==-1) {
    return -1;
  }
  if ( (!filename)||(!path) ) {
    return -2;
  }
  remaps[remap_len].filename=strdup(filename);
  if (!remaps[remap_len].filename) {
    return -3;
  }
  remaps[remap_len].path=strdup(path);
  if (!remaps[remap_len].path) {
    free(remaps[remap_len].filename);
    return -3;
  }
  remap_len++;

  return 0;
}
// }}}

int path_register_prefix(const char *prefix,const char *path) // {{{
{
  if (ensure_pathdata()==-1) {
    return -1;
  }
  if ( (!prefix)||(!path) ) {
    return -2;
  }
  const int len=strlen(prefix);
  remaps[remap_len].prefix=malloc(len+2+1);
  if (!remaps[remap_len].prefix) {
    return -3;
  }
  remaps[remap_len].prefix[0]='[';
  strcpy(remaps[remap_len].prefix+1,prefix);
  remaps[remap_len].prefix[len+1]=']';
  remaps[remap_len].prefix[len+2]=0;

  remaps[remap_len].path=strdup(path);
  if (!remaps[remap_len].path) {
    free(remaps[remap_len].prefix);
    return -3;
  }
  remap_len++;

  return 0;
}
// }}}

static char *concat_path(const char *path,const char *filename) // {{{
{
  const int plen=strlen(path);
  char *ret=malloc(plen+strlen(filename)+2);
  if (!ret) {
    return NULL;
  }
  strcpy(ret,path);
  ret[plen]='/';
  strcpy(ret+plen+1,filename);

  return ret;
}
// }}}

xmlParserInputBufferPtr openFileHandler(const char *filename,xmlCharEncoding encoding) // {{{
{
  int iA;
  xmlParserInputBufferPtr ret;

#ifdef DEBUG
  printf("T: %s\n",filename);
#endif
  if (*filename=='/') { // don't care about absolute paths
    return (*old_handler)(filename,encoding);
  }

  for (iA=0;iA<remap_len;iA++) {
    if ( (remaps[iA].filename)&&
         (strcmp(filename,remaps[iA].filename)==0) ) {
      if (remaps[iA].path) {
        char *new_file=concat_path(remaps[iA].path,filename);
        if (!new_file) {
          return NULL;
        }
        ret=xmlParserInputBufferCreateFilename(new_file,encoding);
        free(new_file);
        return ret;
      } else { // static data
        return xmlParserInputBufferCreateStatic(remaps[iA].data,remaps[iA].len,encoding);
      }
    } else if ( (remaps[iA].prefix)&&
                (strncmp(filename,remaps[iA].prefix,strlen(remaps[iA].prefix))==0) ) {
      char *new_file=concat_path(remaps[iA].path,filename+strlen(remaps[iA].prefix));
      if (!new_file) {
        return NULL;
      }
      ret=xmlParserInputBufferCreateFilename(new_file,encoding);
      free(new_file);
      return ret;
    }
  }

  // fallback
  return (*old_handler)(filename,encoding);
}
// }}}

int load_path()
{
/* TODO?
  xmlOutputBufferCreateFilenameFunc old=NULL;
  old=xmlOutputBufferCreateFilenameDefault(XmlZipCreate);

  xmlOutputBufferCreateFilenameDefault(old);
*/
  old_handler=xmlParserInputBufferCreateFilenameDefault(openFileHandler);

#ifdef DEBUG
  xmlRegisterDefaultInputCallbacks();
  xmlRegisterInputCallbacks(mymatch,NULL,NULL,NULL);
#endif

//   xsltRegisterExtModuleFunction((const xmlChar *)"separate",(const xmlChar *)"thax.home/split",thobiStrSeparateFunction);
   return 1;
}

void unload_path()
{
  xmlParserInputBufferCreateFilenameDefault(old_handler);
  free_pathdata();
}

#ifdef STANDALONE
int thax_home_path_init()
{
  return load_path();
}
#endif
