CFLAGS=-O2
LDFLAGS=
LDLIBS=-lm -lpthread

WWWDIR=/var/www/inf-dice/n4
BINDIR=/usr/local/bin

WWW_TARGETS=hitbar.css hex.png unit_data.js weapon_data.js hacking_data.js
BIN_TARGETS=inf-dice-n4

all: ${WWW_TARGETS} ${BIN_TARGETS}

clean:
	rm -f ${WWW_TARGETS} ${BIN_TARGETS} inf-dice.o

inf-dice-n4: inf-dice.o
	${CC} ${CFLAGS} ${LDFLAGS} ${LDLIBS} $< -o $@

inf-dice.o: inf-dice.c

hitbar.css: hitbar.pl
	./hitbar.pl > hitbar.css

hex.png: hexgrid.pl
	./hexgrid.pl 100 hex.png

install: ${WWW_TARGETS} ${BIN_TARGETS}
	cp inf-dice.js inf-dice.css inf-dice.pl ${WWW_TARGETS} ${WWWDIR}
	cp inf-dice-n4 ${BINDIR}

diff:
	for i in ${WWW_TARGETS}; do diff -U 10 ${WWWDIR} $$i; done

test: inf-dice-n4
	./test.pl
