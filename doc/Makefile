.dummy:

all: .dummy
	$(MAKE) doc.pdf
	$(MAKE) doc.html

doc.pdf: .dummy
	pdflatex doc.tex
	pdflatex doc.tex

doc.html: .dummy
	mkdir -p html/
	ln -sf doc.l2h .latex2html-init
	latex2html -rootdir html/ -local_icons -split 4 -link 0 -info 0 -no_footnode -noauto_navigation doc.tex -t "Z4800 Documentation"
	find html/ -name \*.html -exec ./doc_post.pl \{\} \;
	cp doc.css csshover3.htc html/

clean: .dummy
	rm -f doc.pdf doc.html *.aux *.bbl *.blg *.bat *.out *.log *.toc
	rm -rf html/
