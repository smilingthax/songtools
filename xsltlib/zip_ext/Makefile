SOURCES=zipext.c
MODULE=thax_home_zip_ext.so

CPPFLAGS=-O3 -Wall $(FLAGS) -g -DSTANDALONE

PACKAGES=libxslt minizip

PKG_CONFIG=pkg-config
CPPFLAGS+=$(and $(PACKAGES),$(shell $(PKG_CONFIG) --cflags $(PACKAGES)))
LDFLAGS+=$(and $(PACKAGES),$(shell $(PKG_CONFIG) --libs $(PACKAGES)))

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

%.d: %.c
	@$(CC) $(CPPFLAGS) -MM -MT"$@" -MT"$*.o" -o $@ $<  2> /dev/null

%.d: %.cpp
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -MM -MT"$@" -MT"$*.o" -o $@ $<  2> /dev/null

$(MODULE): $(OBJECTS)
	$(CXX) -o $@ $^ -shared -rdynamic $(LDFLAGS)

test: force
	xsltproc outzip.xsl in.xml

force:
