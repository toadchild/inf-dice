CFLAGS=-O2
LDFLAGS=
LDLIBS=-lm -lpthread

WWWDIR=/var/www/inf-dice
BINDIR=/usr/local/bin

all: inf-dice hitbar.css hex.png

clean:
	rm -f inf-dice inf-dice.o hitbar.css hex.png

inf-dice: inf-dice.o

inf-dice.o: inf-dice.c

hitbar.css: hitbar.pl
	./hitbar.pl > hitbar.css

hex.png: hexgrid.pl
	./hexgrid.pl 100 hex.png

install: inf-dice hitbar.css hex.png
	cp inf-dice.js inf-dice.css hitbar.css hex.png inf-dice.pl ${WWWDIR}
	cp inf-dice ${BINDIR}
