CFLAGS=-O2
LDFLAGS=
LDLIBS=-lm -lpthread

WWWDIR=/var/www/inf-dice
BINDIR=/usr/local/bin

all: inf-dice

clean:
	rm -f inf-dice inf-dice.o

inf-dice: inf-dice.o

inf-dice.o: inf-dice.c

install: inf-dice
	cp inf-dice.js inf-dice.css inf-dice.pl ${WWWDIR}
	cp inf-dice ${BINDIR}
