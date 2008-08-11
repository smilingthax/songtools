dist:
	$(MAKE) -C ../../xsltlib dist
	rm -rf xsltlib; mkdir xsltlib; cd xsltlib; tar xzf ../../../xsltlib/xsltlib.tgz
	tar czhf songprocessor.tgz xsltlib songprocessor COPYING lgpl.txt
