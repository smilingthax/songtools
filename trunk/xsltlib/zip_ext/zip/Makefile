SOURCES=zip.c unzip.c ioapi.c
LIB1=libzip.a

#CC=/export/gcc3/usr/bin/gcc
#CXX=/export/gcc3/usr/bin/g++
#FLAGS=-I/export/gcc3/usr/include/g++ -I/export/gcc3/usr/include/g++/i486-suse-linux

CFLAGS=-O3 -march=pentium -funroll-all-loops -finline-functions -Wall -g
#CFLAGS=-Wall -g
#LDFLAGS=-g
CPPFLAGS=$(CFLAGS) $(FLAGS)

OBJECTS1=$(SOURCES:.c=.o)
all: $(LIB1)
ifneq "$(MAKECMDGOALS)" "clean"
  -include $(SOURCES:.c=.d)
endif 

clean:
	rm -f $(LIB1) $(OBJECTS1) $(SOURCES:.c=.d)

%.d: %.c
	@$(SHELL) -ec '$(CXX) -MM $(CPPFLAGS) $< \
                      | sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

$(LIB1): $(OBJECTS1)
	$(AR) rcu $@ $^
