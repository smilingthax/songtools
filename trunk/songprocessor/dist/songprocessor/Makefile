SOURCES1=main.c
SOURCES2=process.cpp parseakk.cpp
EXEC1=songprocessor
XML=1

CFLAGS=-O3 -march=pentium -funroll-all-loops -finline-functions -Wall
ifneq "$(STATIC)" "1"
  CFLAGS+=-g
  #LDFLAGS+=-g
endif
CPPFLAGS=$(CFLAGS) $(FLAGS)

ifeq "$(XML)" "1"
#  CPPFLAGS+=-DWITH_XML -I/usr/include/libxml2
#  LDFLAGS+=-lxslt -lexslt -lxml2 -lz -lgcrypt -lgpg-error
  CPPFLAGS+=-DWITH_XML `pkg-config --cflags libxml-2.0 libxslt libexslt`
  LDFLAGS+=`pkg-config --libs libxml-2.0 libxslt libexslt`
endif
ifeq "$(STATIC)" "1"
  LDFLAGS+=-static -pthread -ldl
endif
CPPFLAGS+=-I../xsltlib
LDFLAGS+=../xsltlib/libxsltext.a
FLAGS+=-DDEFAULT_IMPRESS

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

$(EXEC1): $(OBJECTS1)
	$(CXX) -o $@ $^ $(LDFLAGS)
