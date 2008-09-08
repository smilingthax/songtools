#ifndef _PROCESS_H
#define _PROCESS_H

#ifdef __cplusplus
 #include <vector>
 class SongContainer;
 class FlyTextTokens;
 extern std::vector<SongContainer *> songList;
 extern FlyTextTokens flyt;

 int do_process_hlp(char *inputFile,bool with_tex,bool with_plain,bool with_html,bool with_list,bool with_impress,bool with_akk=true,bool with_splitimpress=false);
extern "C" {
#endif

int do_process(char *inputFile,int tex,int plain,int html,int list,int impress,int split_impress);
int do_process_noakk(char *inputFile,int tex,int plain,int html,int list,int impress,int split_impess);

#ifdef __cplusplus
};
#endif

#endif
