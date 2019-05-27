SOURCES1=split.c zipext.c  enclose.c imagefun.c  path.c  regexp.c  akker.c
SOURCES2=extension.cpp chord.cpp speed.cpp processor.cpp parset.cpp ptools.cpp
LIB1=libxsltext.a
DIRS=enclose imagetools mine_ext parset split path zip_ext regexp akker
XML=1

PACKAGES=minizip
#PACKAGES+=libpcre2-8

MINGW=/export/wingcc/suse/usr/bin/i686-w64-mingw32-
LIBBASE=/export/wingcc/suse/usr/i686-w64-mingw32/sys-root/mingw

CC=$(MINGW)gcc
CXX=$(MINGW)g++
STRIP=$(MINGW)strip
AR=$(MINGW)ar
#FLAGS=-I/export/wingcc/include/g++ -I/export/wingcc3/usr/include/g++/i486-suse-linux

# CPPFLAGS=-O3 -Wall -g
CPPFLAGS=-Wall -g
LDFLAGS=-g -lzlib1
CPPFLAGS+=$(FLAGS) -I$(LIBBASE)/include
#-DZLIB_WINAPI

ifeq "$(XML)" "1"
  # PACKAGES+=libxml-2.0  ?
  CPPFLAGS+=-DWITH_XML -I$(LIBBASE)/include/libxml2
endif

ifneq "$(PACKAGES)" ""
  # these must be last in link ordering
  CPPFLAGS+=$(shell PKG_CONFIG_LIBDIR=$(LIBBASE)/lib/pkgconfig/ pkg-config --define-variable=prefix=$(LIBBASE) --cflags $(PACKAGES))
  LDFLAGS+=$(shell PKG_CONFIG_LIBDIR=$(LIBBASE)/lib/pkgconfig/ pkg-config --define-variable=prefix=$(LIBBASE) --libs $(PACKAGES))
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
	@$(CC) $(CPPFLAGS) -MM -MT"$@" -MT"$*.o" -o $@ $<  2> /dev/null

%.d: ../*/%.cpp
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -MM -MT"$@" -MT"$*.o" -o $@ $<  2> /dev/null

%.o: ../*/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

%.o: ../*/%.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -o $@ -c $<

$(LIB1): $(OBJECTS1)
	$(AR) rscu $@ $^
