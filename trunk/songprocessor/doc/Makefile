SOURCE=tags.xml rechtedb.xml
STYLE=docu.xsl

DOC=$(SOURCE:.xml=.html)
all: $(DOC)

clean:
	rm -f $(DOC)

%.html: %.xml $(STYLE)
	cat $< | sed "s/<code[^>]*>/\0<\![CDATA[/g;s/<\/code>/]]>\0/g" | xsltproc -o $@ $(STYLE) -

$(LINK1):
	ln -s ../$@ .

upload: $(DOC)
	scp $^ root@main:/export/teestube/upload/ci/songs/
