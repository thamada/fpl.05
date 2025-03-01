



all :
	platex fpl05.tex
	bibtex fpl05
	platex fpl05.tex

s : show

show :
	xdvi fpl05.dvi &
#	xdvi -p 400 fpl05.dvi &


ps :
	dvips fpl05.dvi -o fpl05.ps
	dvipdf fpl05.dvi 

c : clean

clean : 
	rm -rf fpl05.{dvi,ps,pdf} *~

l :
	emacs -nw fpl05.tex
