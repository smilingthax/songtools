SOURCES=regexp.c
MODULE=exslt_org_regexp.dll

MINGW=/export/wingcc/suse/usr/bin/i686-w64-mingw32-
LIBBASE=/export/wingcc/suse/usr/i686-w64-mingw32/sys-root/mingw

CC=$(MINGW)gcc
CXX=$(MINGW)g++
STRIP=$(MINGW)strip

CPPFLAGS=-O3 -Wall -DSTANDALONE
PACKAGES+=libxslt libpcre2-8

ifneq "$(PACKAGES)" ""
  # these must be last in link ordering
  CPPFLAGS+=$(shell PKG_CONFIG_LIBDIR=$(LIBBASE)/lib/pkgconfig/ pkg-config --define-variable=prefix=$(LIBBASE) --cflags $(PACKAGES))
  LDFLAGS+=$(shell PKG_CONFIG_LIBDIR=$(LIBBASE)/lib/pkgconfig/ pkg-config --define-variable=prefix=$(LIBBASE) --libs $(PACKAGES))
endif

OBJECTS=$(patsubst %.c,$(PREFIX)%$(SUFFIX).o,\
        $(patsubst %.cpp,$(PREFIX)%$(SUFFIX).o,\
$(SOURCES)))
DEPENDS=$(patsubst %.c,$(PREFIX)%$(SUFFIX).d,\
        $(patsubst %.cpp,$(PREFIX)%$(SUFFIX).d,\
        $(filter-out %.o,""\
$(SOURCES))))

all: $(MODULE)
ifneq "$(MAKECMDGOALS)" "clean"
  -include $(DEPENDS)
endif

clean:
	rm -f $(MODULE) $(OBJECTS) $(DEPENDS)

%.d: ../%.c
	@$(CC) $(CPPFLAGS) -MM -MT"$@" -MT"$*.o" -o $@ $<  2> /dev/null

%.d: ../%.cpp
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -MM -MT"$@" -MT"$*.o" -o $@ $<  2> /dev/null

%.o: ../%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

%.o: ../%.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -o $@ -c $<

$(MODULE): $(OBJECTS)
	$(CXX) -o $@ $^ -shared $(LDFLAGS)
	$(STRIP) $@
