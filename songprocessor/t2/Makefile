all: clean pdf
pdf: main.pdf 

%.dvi: %.tex
	latex $<
%.pdf: %.tex
	pdflatex $<
view: main.dvi 
	xdvi main.dvi
clean:
	$(RM) main.dvi main.pdf 

mrproper: clean
	$(RM) main.drt main.log main.out main.aux

in1.tex:
	ln -s ../in1.tex .
	ln -s ../plain .

main.pdf: in1.tex

.PHONY: clean all pdf view mrproper
