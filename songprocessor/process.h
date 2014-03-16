#ifndef _PROCESS_H
#define _PROCESS_H

typedef struct {
  int out_tex : 1;
  int out_plain : 1;
  int out_html : 1;
  int out_list : 1;
  int out_impress : 1;
  int out_snippet : 1;

  int inter_noakk : 1;
  int inter_noshow : 1;

  int split_impress : 1;
} process_data_t;

#ifdef __cplusplus
 #include <vector>
 #include <stdio.h>

 class SongContainer;
 class FlyTextTokens;
 extern std::vector<SongContainer *> songList;
 extern FlyTextTokens flyt;

 int do_process_hlp(char *inputFile,process_data_t &opts,const char *imgpath=NULL,const char *preset=NULL,const char *special=NULL);
extern "C" {
#endif

int do_process(char *inputFile,process_data_t *opts,const char *imgpath,const char *preset,const char *special);

#ifdef __cplusplus
};
#endif

#endif
