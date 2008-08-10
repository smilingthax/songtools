SOURCES=ext4.c
MODULE=thax_home_zip_ext.dll
LINK1=ext4.c zipext.h

MINGW=i586-mingw32msvc-
CC=$(MINGW)gcc
CXX=$(MINGW)g++
STRIP=$(MINGW)strip

LIBXMLPATH=/export/wingcc/libxml2-2.6.23.win32
LIBXSLTPATH=/export/wingcc/libxslt-1.1.15.win32
ICONVPATH=/export/wingcc/iconv-1.9.1.win32
ZLIBPATH=/export/wingcc/zlib-1.2.3.win32

CPPFLAGS=-O3 -march=pentium -funroll-all-loops -finline-functions -Wall -DSTANDALONE
#CPPFLAGS+=`pkg-config --cflags libxml-2.0`
CPPFLAGS+=-I$(LIBXMLPATH)/include -I$(LIBXSLTPATH)/include -I$(ICONVPATH)/include -I$(ZLIBPATH)/include
LDFLAGS=-L$(LIBXMLPATH)/bin -lxml2 -L$(LIBXSLTPATH)/bin -lxslt -L$(ICONVPATH)/bin -liconv -L$(ZLIBPATH)/bin -lzlib1 zip/libzip.a

OBJECTS=$(patsubst %.c,$(PREFIX)%$(SUFFIX).o,\
        $(patsubst %.cpp,$(PREFIX)%$(SUFFIX).o,\
$(SOURCES)))
DEPENDS=$(patsubst %.c,$(PREFIX)%$(SUFFIX).d,\
        $(patsubst %.cpp,$(PREFIX)%$(SUFFIX).d,\
        $(filter-out %.o,""\
$(SOURCES))))

all: $(LINK1) $(MODULE)
ifneq "$(MAKECMDGOALS)" "clean"
 ifneq "$(MAKECMDGOALS)" "cleanlinks"
  -include $(DEPENDS)
 endif 
endif 

clean:
	rm -f $(MODULE) $(OBJECTS) $(DEPENDS)
	$(MAKE) -C zip clean
cleanlinks:
	rm -f $(LINK1) 
	$(MAKE) -C zip cleanlinks

%.d: %.c
	@$(SHELL) -ec '$(CC) -MM $(CPPFLAGS) $< \
                      | sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'
%.d: %.cpp
	@$(SHELL) -ec '$(CXX) -MM $(CPPFLAGS) $< \
                      | sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

zip/libzip.a:
	$(MAKE) -C zip

$(MODULE): $(OBJECTS)
	$(CXX) -o $@ $^ -shared $(LDFLAGS)
	$(STRIP) $@

$(LINK1):
	ln -s ../$@ .

