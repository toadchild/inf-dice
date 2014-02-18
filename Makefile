CFLAGS=-O2
LDFLAGS=
LDLIBS=-lm -lpthread

WWWDIR=/var/www/inf-dice
BINDIR=/usr/local/bin

all: inf-dice hitbar.css

clean:
	rm -f inf-dice inf-dice.o

inf-dice: inf-dice.o

inf-dice.o: inf-dice.c

hitbar.css: hitbar.pl
	./hitbar.pl > hitbar.css

install: inf-dice hitbar.css
	cp inf-dice.js inf-dice.css hitbar.css inf-dice.pl ${WWWDIR}
	cp inf-dice ${BINDIR}
