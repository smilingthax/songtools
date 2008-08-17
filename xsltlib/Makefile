SOURCES1=split.c zipext.c  zip.c unzip.c ioapi.c  enclose.c imagefun.c
SOURCES2=textItem.cpp extension.cpp speed.cpp processor.cpp parset.cpp ptools.cpp
LIB1=libxsltext.a
DIRS=enclose imagetools mine_ext parset split

CFLAGS=-O3 -funroll-all-loops -finline-functions -Wall -g
CFLAGS+=`pkg-config --cflags libxml-2.0`
#CFLAGS=-Wall -g
#LDFLAGS=-g
CPPFLAGS:=$(CFLAGS) $(FLAGS)
CFLAGS:=

OBJECTS1=$(SOURCES1:.c=.o) $(SOURCES2:.cpp=.o)
all: $(LIB1)
subdirs: 
	$(SHELL) -ec 'for i in $(DIRS); do \
                         $(MAKE) -C $$i; \
                       done'
subdirs-%:
	@$(SHELL) -ec 'for i in $(DIRS); do \
                         $(MAKE) -C $$i $*; \
                       done'

ifneq "$(MAKECMDGOALS)" "clean"
  -include $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d)
endif 

clean:
	rm -f $(LIB1) $(OBJECTS1) $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d) xsltlib.tgz

%.d: */%.c
	@$(SHELL) -ec '$(CC) -MM $(CPPFLAGS) $< \
                      | sed '\''s�\($*\)\.o[ :]*�\1.o $@ : �g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'
		      
%.d: */%.cpp
	@$(SHELL) -ec '$(CXX) -MM $(CPPFLAGS) $< \
                      | sed '\''s�\($*\)\.o[ :]*�\1.o $@ : �g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'

%.d: zip_ext/zip/%.c
	@$(SHELL) -ec '$(CC) -MM $(CPPFLAGS) $< \
                      | sed '\''s�\($*\)\.o[ :]*�\1.o $@ : �g'\'' > $@;\
                      [ -s $@ ] || rm -f $@'
     
%.o: */%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

%.o: */%.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -o $@ -c $<

%.o: zip_ext/zip/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

$(LIB1): $(OBJECTS1)
	$(AR) rcu $@ $^