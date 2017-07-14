#ifndef _PATH_H
#define _PATH_H
/* Copyright by Tobias Hoffmann, Licence: LGPL/MIT, see COPYING
 * This file may, by your choice, be licensed under LGPL or by the MIT license.*/

#ifdef __cplusplus
extern "C" {
#endif

int load_path();
int path_register_static_file(const char *filename,const char *data,int len); // i.e. "filename" contains (data,len)
int path_register_remap(const char *filename,const char *path);
int path_register_prefix(const char *prefix,const char *path); // [prefix] will be substituted by path

#ifdef __cplusplus
};
#endif

#endif
