SOURCES1=split.c zipext.c  zip.c unzip.c ioapi.c  enclose.c imagefun.c  path.c
SOURCES2=extension.cpp chord.cpp speed.cpp processor.cpp parset.cpp ptools.cpp
LIB1=libxsltext.a
DIRS=enclose imagetools mine_ext parset split path zip_ext
XML=1

MINGW=/export/wingcc/suse/usr/bin/i686-w64-mingw32-
LIBBASE=/export/wingcc/suse/usr/i686-w64-mingw32/sys-root/mingw

CC=$(MINGW)gcc
CXX=$(MINGW)g++
STRIP=$(MINGW)strip
AR=$(MINGW)ar
#FLAGS=-I/export/wingcc/include/g++ -I/export/wingcc3/usr/include/g++/i486-suse-linux

# CFLAGS=-O3 -funroll-all-loops -finline-functions -Wall -g
CFLAGS=-Wall -g
LDFLAGS=-g -L$(ZLIBPATH)/bin -lzlib1
CPPFLAGS=$(CFLAGS) $(FLAGS) -I$(LIBBASE)/include
#-DZLIB_WINAPI

ifeq "$(XML)" "1"
  CPPFLAGS+=-DWITH_XML -I$(LIBBASE)/include/libxml2
endif

OBJECTS1=$(SOURCES1:.c=.o) $(SOURCES2:.cpp=.o)
all: $(LIB1)
subdirs:
	@$(SHELL) -ec 'for i in $(patsubst %,../%,$(DIRS)); do \
                         $(MAKE) -C $$i/win; \
                       done'
subdirs-%:
	@$(SHELL) -ec 'for i in $(patsubst %,../%,$(DIRS)); do \
                         $(MAKE) -C $$i/win $*; \
                       done'

ifneq "$(MAKECMDGOALS)" "clean"
  -include $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d)
endif

clean:
	rm -f $(LIB1) $(OBJECTS1) $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d)

%.d: ../*/%.c
	@$(SHELL) -ec '$(CC) -MM $(CPPFLAGS) $< \
                      | sed '\''s§\($*\)\.o[ :]*§\1.o $@ : §g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

%.d: ../*/%.cpp
	@$(SHELL) -ec '$(CXX) -MM $(CPPFLAGS) $< \
                      | sed '\''s§\($*\)\.o[ :]*§\1.o $@ : §g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

%.d: ../zip_ext/zip/%.c
	@$(SHELL) -ec '$(CC) -MM $(CPPFLAGS) $< \
                      | sed '\''s§\($*\)\.o[ :]*§\1.o $@ : §g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

%.o: ../*/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

%.o: ../*/%.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -o $@ -c $<

%.o: ../zip_ext/zip/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

$(LIB1): $(OBJECTS1)
	$(AR) rscu $@ $^
