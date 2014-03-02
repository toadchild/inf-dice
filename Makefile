CFLAGS=-O2
LDFLAGS=
LDLIBS=-lm -lpthread

WWWDIR=/var/www/inf-dice
BINDIR=/usr/local/bin

WWW_TARGETS=hitbar.css hex.png unit_data.js
BIN_TARGETS=inf-dice

all: ${WWW_TARGETS} ${BIN_TARGETS}

clean:
	rm -f ${WWW_TARGETS} ${BIN_TARGETS}

inf-dice: inf-dice.o

inf-dice.o: inf-dice.c

hitbar.css: hitbar.pl
	./hitbar.pl > hitbar.css

hex.png: hexgrid.pl
	./hexgrid.pl 100 hex.png

unit_data.js: process_unit.pl ia-data/*
	./process_unit.pl

install: ${WWW_TARGETS} ${BIN_TARGETS}
	cp inf-dice.js inf-dice.css inf-dice.pl ${WWW_TARGETS} ${WWWDIR}
	cp inf-dice ${BINDIR}
