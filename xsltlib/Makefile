SOURCES1=split.c zipext.c  enclose.c imagefun.c  path.c  regexp.c  akker.c
SOURCES2=extension.cpp chord.cpp speed.cpp processor.cpp parset.cpp ptools.cpp
LIB1=libxsltext.a
DIRS=enclose imagetools mine_ext parset split path zip_ext regexp akker

PACKAGES=libxslt libexslt minizip  # libxml-2.0
PACKAGES+=libpcre2-8

include config.mk

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
	@$(CC) $(CPPFLAGS) -MM -MT"$@" -MT"$*.o" -o $@ $<  2> /dev/null

%.d: */%.cpp
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -MM -MT"$@" -MT"$*.o" -o $@ $<  2> /dev/null

%.o: */%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

%.o: */%.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -o $@ -c $<


$(LIB1): $(OBJECTS1)
	$(AR) rsc $@ $^
