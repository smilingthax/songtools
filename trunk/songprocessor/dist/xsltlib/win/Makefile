SOURCES1=split.c zipext.c zip/ioapi.c zip/zip.c zip/unzip.c enclose.c imagefun.c
SOURCES2=textItem.cpp extension.cpp speed.cpp processor.cpp parset.cpp ptools.cpp
LIB1=libxsltext.a
LINK1=split.c textItem.cpp extension.cpp parset.cpp processor.cpp speed.cpp enclose.c enclose.h ptools.cpp ptools.h\
      split.h textItem.h extension.h parset.h processor.h zipext.c zipext.h imagefun.c imagefun.h\
      zip/crypt.h zip/ioapi.c zip/ioapi.h zip/iowin32.c zip/iowin32.h zip/unzip.c zip/unzip.h zip/zip.c zip/zip.h
XML=1

#MINGW=/export/wingcc/i386-mingw32msvc/bin/
MINGW=i586-mingw32msvc-
CC=$(MINGW)gcc
CXX=$(MINGW)g++
STRIP=$(MINGW)strip
AR=$(MINGW)ar
#FLAGS=-I/export/wingcc/include/g++ -I/export/wingcc3/usr/include/g++/i486-suse-linux

LIBXMLPATH=/export/wingcc/libxml2-2.6.23.win32
LIBXSLTPATH=/export/wingcc/libxslt-1.1.15.win32
ICONVPATH=/export/wingcc/iconv-1.9.1.win32
ZLIBPATH=/export/wingcc/zlib-1.2.3.win32

# CFLAGS=-O3 -march=pentium -funroll-all-loops -finline-functions -Wall -g
CFLAGS=-Wall -g
LDFLAGS=-g -L$(ZLIBPATH)/bin -lzlib1
CPPFLAGS=$(CFLAGS) $(FLAGS) -I$(ZLIBPATH)/include 
#-DZLIB_WINAPI

ifeq "$(XML)" "1"
  CPPFLAGS+=-DWITH_XML -I$(LIBXMLPATH)/include -I$(LIBXSLTPATH)/include -I$(ICONVPATH)/include
endif

OBJECTS1=$(SOURCES1:.c=.o) $(SOURCES2:.cpp=.o)
all: $(LINK1) $(LIB1)
ifneq "$(MAKECMDGOALS)" "clean"
 ifneq "$(MAKECMDGOALS)" "cleanlinks"
  -include $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d)
 endif
endif 

clean:
	rm -f $(LIB1) $(OBJECTS1) $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d)
cleanlinks:
	rm -f $(LINK1) 
	rm -rf dist/

%.d: %.c
	@$(SHELL) -ec '$(CXX) -MM $(CPPFLAGS) $< \
                      | sed '\''s§\($*\)\.o[ :]*§\1.o $@ : §g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

%.d: %.cpp
	@$(SHELL) -ec '$(CXX) -MM $(CPPFLAGS) $< \
                      | sed '\''s§\($*\)\.o[ :]*§\1.o $@ : §g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

$(LIB1): $(OBJECTS1)
	$(AR) rscu $@ $^

$(LINK1):
	ln -s ../$(patsubst zip/%,../zip/%,$@) $(dir $@)

force:
