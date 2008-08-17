SOURCES=zipext.c
MODULE=thax_home_zip_ext.so

CPPFLAGS=-O3 -march=pentium -funroll-all-loops -finline-functions -Wall $(FLAGS) -g -DSTANDALONE
CPPFLAGS+=`pkg-config --cflags libxml-2.0`

OBJECTS=$(patsubst %.c,$(PREFIX)%$(SUFFIX).o,\
        $(patsubst %.cpp,$(PREFIX)%$(SUFFIX).o,\
$(SOURCES))) zip/libzip.a
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
	$(MAKE) -C zip clean

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
	$(CXX) -o $@ $^ -shared -rdynamic

test: force
	xsltproc outzip.xsl in.xml

force:
