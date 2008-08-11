SOURCES1=split.c zipext.c zip/zip.c zip/unzip.c zip/ioapi.c enclose.c imagefun.c
SOURCES2=textItem.cpp extension.cpp speed.cpp processor.cpp parset.cpp ptools.cpp
LIB1=libxsltext.a

#CC=/export/gcc3/usr/bin/gcc
#CXX=/export/gcc3/usr/bin/g++
#FLAGS=-I/export/gcc3/usr/include/g++ -I/export/gcc3/usr/include/g++/i486-suse-linux

CFLAGS=-O3 -march=pentium -funroll-all-loops -finline-functions -Wall -g
CFLAGS+=`pkg-config --cflags libxml-2.0`
#CFLAGS=-Wall -g
#LDFLAGS=-g
CPPFLAGS:=$(CFLAGS) $(FLAGS)
CFLAGS:=

OBJECTS1=$(SOURCES1:.c=.o) $(SOURCES2:.cpp=.o)
all: $(LIB1)
ifneq "$(MAKECMDGOALS)" "clean"
  -include $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d)
endif 

clean:
	rm -f $(LIB1) $(OBJECTS1) $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d) xsltlib.tgz

%.d: %.c
	@$(SHELL) -ec '$(CC) -MM $(CPPFLAGS) $< \
                      | sed '\''s§\($*\)\.o[ :]*§\1.o $@ : §g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'
		      
%.d: %.cpp
	@$(SHELL) -ec '$(CXX) -MM $(CPPFLAGS) $< \
                      | sed '\''s§\($*\)\.o[ :]*§\1.o $@ : §g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

$(LIB1): $(OBJECTS1)
	$(AR) rcu $@ $^

dist:
	tar czh --no-recursion -f xsltlib.tgz *.c *.cpp *.h *.xsl win/ win/Makefile win/zip/ zip/ zip/*.c zip/*.h Makefile 
