SOURCES=zip.c unzip.c ioapi.c
LIB1=libzip.a

#MINGW=/export/wingcc/i386-mingw32msvc/bin/
MINGW=i586-mingw32msvc-
CC=$(MINGW)gcc
CXX=$(MINGW)g++
STRIP=$(MINGW)strip
AR=$(MINGW)ar
#FLAGS=-I/export/gcc3/usr/include/g++ -I/export/gcc3/usr/include/g++/i486-suse-linux

ZLIBPATH=/export/wingcc/zlib-1.2.3.win32

CFLAGS=-O3 -funroll-all-loops -finline-functions -Wall -g
#CFLAGS=-Wall -g
#LDFLAGS=-g
CPPFLAGS=$(CFLAGS) $(FLAGS) -I$(ZLIBPATH)/include 

OBJECTS1=$(SOURCES:.c=.o)
all: $(LIB1)
ifneq "$(MAKECMDGOALS)" "clean"
  -include $(SOURCES:.c=.d)
endif 

clean:
	rm -f $(LIB1) $(OBJECTS1) $(SOURCES:.c=.d)

%.d: ../../zip/%.c
	@$(SHELL) -ec '$(CC) -MM $(CPPFLAGS) $< \
                      | sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

%.o: ../../zip/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

%.o: ../../zip/%.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -o $@ -c $<

$(LIB1): $(OBJECTS1)
	$(AR) rscu $@ $^
