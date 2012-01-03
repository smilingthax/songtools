#ifndef _PROCESS_H
#define _PROCESS_H

#ifdef __cplusplus
 #include <vector>
 #include <stdio.h>

 class SongContainer;
 class FlyTextTokens;
 extern std::vector<SongContainer *> songList;
 extern FlyTextTokens flyt;

 int do_process_hlp(char *inputFile,bool with_tex,bool with_plain,bool with_html,bool with_list,bool with_impress,bool with_snippet,bool with_akk=true,bool with_splitimpress=false,const char *imgpath=NULL,const char *preset=NULL);
extern "C" {
#endif

int do_process(char *inputFile,int tex,int plain,int html,int list,int impress,int split_impress,int snippet,int with_akk,const char *imgpath,const char *preset);

#ifdef __cplusplus
};
#endif

#endif
