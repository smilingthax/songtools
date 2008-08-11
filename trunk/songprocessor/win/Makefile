SOURCES1=main.c
SOURCES2=process.cpp parseakk.cpp
EXEC1=songprocessor.exe
LINK1=main.c process.cpp parseakk.cpp \
             process.h parseakk.h 
LINK2=$(EXEC1) ../shet.xsl ../split.xsl ../hateemel.xsl ../puretext.xsl ../tex.xsl ../rights-full.xsl ../lang-db.xsl ../songs.xml \
               ../songbook-db.xsl ../verlage.xml \
               ../helper/no-akk.xsl ../helper/sort.xsl ../helper/split-lang.xsl ../helper/copyright-check.xsl ../helper/addrights.xsl \
	       ../impress.xsl \
	       ../doc/tags.html ../doc/rechtedb.html \
               $(wildcard ../../xsltext*/win/*.dll)
TEXLINK=Makefile pdftex.cfg songfoil.cls addfont.map main.tex songffnt.def \
        arial.tfm arialb.tfm arials.tfm arial.ttf arialb.ttf ariali.ttf 
OOTLINK=content.xml styles.xml
XML=1

#MINGW=/export/wingcc/i386-mingw32msvc/bin/
MINGW=i586-mingw32msvc-
CC=$(MINGW)gcc
CXX=$(MINGW)g++
STRIP=$(MINGW)strip
#FLAGS=-I/export/wingcc/include/g++ -I/export/wingcc3/usr/include/g++/i486-suse-linux
RSYNC=rsync --progress --stats

LIBXMLPATH=/export/wingcc/libxml2-2.6.23.win32
LIBXSLTPATH=/export/wingcc/libxslt-1.1.15.win32
ICONVPATH=/export/wingcc/iconv-1.9.1.win32
ZLIBPATH=/export/wingcc/zlib-1.2.3.win32

# CFLAGS=-O3 -march=pentium -funroll-all-loops -finline-functions -Wall -g
CFLAGS=-Wall -g
LDFLAGS=-g -L$(ZLIBPATH)/bin -lzlib1
CPPFLAGS=$(CFLAGS) $(FLAGS) -I$(ZLIBPATH)/include 
#-DZLIB_WINAPI

ifeq "$(XML)" "1"
  CPPFLAGS+=-DWITH_XML -I$(LIBXMLPATH)/include -I$(LIBXSLTPATH)/include -I$(ICONVPATH)/include -I../../xsltlib/
  LDFLAGS+=-L$(LIBXMLPATH)/bin -L$(LIBXSLTPATH)/bin -lxml2 -lxslt -lexslt ../../xsltlib/win/libxsltext.a
endif
FLAGS+=-DDEFAULT_IMPRESS

OBJECTS1=$(SOURCES1:.c=.o) $(SOURCES2:.cpp=.o)
all: $(LINK1) $(EXEC1) dist
ifneq "$(MAKECMDGOALS)" "clean"
 ifneq "$(MAKECMDGOALS)" "cleanlinks"
  -include $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d)
 endif
endif 

clean:
	rm -f $(EXEC1) $(OBJECTS1) $(SOURCES1:.c=.d) $(SOURCES2:.cpp=.d)
cleanlinks:
	rm -f $(LINK1) 
	rm -rf dist/

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

$(LINK1):
	ln -s ../$@ .

dist/: $(EXEC1)
	@mkdir dist
	@mkdir dist/tex
	@mkdir dist/oo-template dist/oo-impress
	ln -s $(LINK2:%=../%) $(LIBXMLPATH)/bin/libxml2.dll  \
              $(LIBXSLTPATH)/bin/libxslt.dll $(LIBXSLTPATH)/bin/libexslt.dll $(LIBXSLTPATH)/bin/xsltproc.exe \
              $(ICONVPATH)/bin/iconv.dll $(ZLIBPATH)/bin/zlib1.dll dist/
	ln -s $(OOTLINK:%=../../../oo-template/%) dist/oo-template
	ln -s $(TEXLINK:%=../../../t2/%) dist/tex

distupload/: $(EXEC1) dist/
	$(STRIP) $(EXEC1)
	@mkdir distupload
	(cd dist; zip ../distupload/files.zip -r * -x *.xml *.dll *.ttf *.tfm xsltproc.exe)
	(cd dist; zip ../distupload/common.zip -r * -i *.dll *.ttf *.tfm xsltproc.exe)
	ln -s ../songs.xml songs-thobi.xml
	ln -s ../verlage.xml .
	zip -j distupload/songs.zip songs-thobi.xml verlage.xml
	rm songs-thobi.xml verlage.xml
	cp ../doc/tags.html ../doc/rechtedb.html distupload/

upload: $(EXEC1) distupload/
	$(RSYNC) distupload/files.zip distupload/common.zip distupload/tags.html distupload/rechtedb.html distupload/songs.zip \
	         root@main:/export/teestube/upload/ci/songs/
