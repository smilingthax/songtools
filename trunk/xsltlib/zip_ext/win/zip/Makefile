SOURCES=zip.c unzip.c ioapi.c
LIB1=libzip.a
LINK1=crypt.h ioapi.c ioapi.h iowin32.c iowin32.h unzip.c unzip.h zip.c zip.h

#MINGW=/export/wingcc/i386-mingw32msvc/bin/
MINGW=i586-mingw32msvc-
CC=$(MINGW)gcc
CXX=$(MINGW)g++
STRIP=$(MINGW)strip
AR=$(MINGW)ar
#FLAGS=-I/export/gcc3/usr/include/g++ -I/export/gcc3/usr/include/g++/i486-suse-linux

ZLIBPATH=/export/wingcc/zlib-1.2.3.win32

CFLAGS=-O3 -march=pentium -funroll-all-loops -finline-functions -Wall -g
#CFLAGS=-Wall -g
#LDFLAGS=-g
CPPFLAGS=$(CFLAGS) $(FLAGS) -I$(ZLIBPATH)/include 

OBJECTS1=$(SOURCES:.c=.o)
all: $(LINK1) $(LIB1)
ifneq "$(MAKECMDGOALS)" "clean"
 ifneq "$(MAKECMDGOALS)" "cleanlinks"
  -include $(SOURCES:.c=.d)
 endif 
endif 

clean:
	rm -f $(LIB1) $(OBJECTS1) $(SOURCES:.c=.d)
cleanlinks:
	rm -f $(LINK1) 

%.d: %.c
	@$(SHELL) -ec '$(CXX) -MM $(CPPFLAGS) $< \
                      | sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

$(LIB1): $(OBJECTS1)
	$(AR) rscu $@ $^

$(LINK1):
	ln -s ../../zip/$@ .
