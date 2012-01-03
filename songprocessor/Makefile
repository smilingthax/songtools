SOURCES1=main.c
SOURCES2=process.cpp parseakk.cpp
EXEC1=pasr
XML=1

#CC=/export/gcc3/usr/bin/gcc
#CXX=/export/gcc3/usr/bin/g++
#FLAGS=-I/export/gcc3/usr/include/g++ -I/export/gcc3/usr/include/g++/i486-suse-linux

CFLAGS=-O3 -funroll-all-loops -finline-functions -Wall
ifneq "$(STATIC)" "1"
  CFLAGS+=-g
  #LDFLAGS+=-g
endif
CPPFLAGS=$(CFLAGS) $(FLAGS)

ifeq "$(XML)" "1"
#  CPPFLAGS+=-DWITH_XML -I/usr/include/libxml2
  #-I/usr/local/include/libxml2
#  LDFLAGS+=-lxslt -lexslt -lxml2 -lz -lgcrypt -lgpg-error
#  LDFLAGS+=-lxslt -lexslt
  #/usr/local/lib/libxml2.a
  PACKAGES+=libxml-2.0 libxslt libexslt
endif

CPPFLAGS+=$(shell pkg-config --cflags $(PACKAGES))
LDFLAGS+=$(shell pkg-config --libs $(PACKAGES))

ifeq "$(STATIC)" "1"
  LDFLAGS+=-static -pthread -ldl -lgcrypt -lgpg-error
#  LDFLAGS+=-static -pthread -ldl
endif

CPPFLAGS+=-I../xsltlib
LDFLAGS+=../xsltlib/libxsltext.a -lz

OBJECTS1=$(SOURCES1:.c=.o) $(SOURCES2:.cpp=.o)
all: $(EXEC1)
ifneq "$(MAKECMDGOALS)" "clean"
  -include $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d)
endif 

clean:
	rm -f $(EXEC1) $(OBJECTS1) $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d)

%.d: %.c
	@$(SHELL) -ec '$(CXX) -MM $(CPPFLAGS) $< \
                      | sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

%.d: %.cpp
	@$(SHELL) -ec '$(CXX) -MM $(CPPFLAGS) $< \
                      | sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

$(EXEC1): ../xsltlib/libxsltext.a
$(EXEC1): $(OBJECTS1)
	$(CXX) -o $@ $^ $(LDFLAGS)
