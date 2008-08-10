SOURCES=enclose.c
MODULE=thax_home_enclose.dll
LINK1=enclose.c enclose.h

MINGW=i586-mingw32msvc-
CC=$(MINGW)gcc
CXX=$(MINGW)g++
STRIP=$(MINGW)strip

LIBXMLPATH=/export/wingcc/libxml2-2.6.23.win32
LIBXSLTPATH=/export/wingcc/libxslt-1.1.15.win32
ICONVPATH=/export/wingcc/iconv-1.9.1.win32

CPPFLAGS=-O3 -march=pentium -funroll-all-loops -finline-functions -Wall -DSTANDALONE
#CPPFLAGS+=`pkg-config --cflags libxml-2.0`
CPPFLAGS+=-I$(LIBXMLPATH)/include -I$(LIBXSLTPATH)/include -I$(ICONVPATH)/include
LDFLAGS=-L$(LIBXMLPATH)/bin -lxml2 -L$(LIBXSLTPATH)/bin -lxslt -L$(ICONVPATH)/bin -liconv

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
cleanlinks:
	rm -f $(LINK1) 

%.d: %.c
	@$(SHELL) -ec '$(CC) -MM $(CPPFLAGS) $< \
                      | sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'
%.d: %.cpp
	@$(SHELL) -ec '$(CXX) -MM $(CPPFLAGS) $< \
                      | sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

$(MODULE): $(OBJECTS)
	$(CXX) -o $@ $^ -shared $(LDFLAGS)
	$(STRIP) $@

$(LINK1):
	ln -s ../$@ .

