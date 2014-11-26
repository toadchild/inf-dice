CFLAGS=-O2
LDFLAGS=
LDLIBS=-lm -lpthread

WWWDIR=/var/www/inf-dice/n3
BINDIR=/usr/local/bin

WWW_TARGETS=hitbar.css hex.png unit_data.js weapon_data.js .htaccess
BIN_TARGETS=inf-dice-n3

all: ${WWW_TARGETS} ${BIN_TARGETS}

clean:
	rm -f ${WWW_TARGETS} ${BIN_TARGETS} dual_weapons.dat dual_ccw.dat inf-dice.o

inf-dice-n3: inf-dice.o
	${CC} ${CFLAGS} ${LDFLAGS} ${LDLIBS} $< -o $@

inf-dice.o: inf-dice.c

hitbar.css: hitbar.pl
	./hitbar.pl > hitbar.css

hex.png: hexgrid.pl
	./hexgrid.pl 100 hex.png

dual_weapons.dat: process_unit.pl ia-data/*
	./process_unit.pl

dual_ccw.dat: process_unit.pl ia-data/*
	./process_unit.pl

unit_data.js: process_unit.pl ia-data/*
	./process_unit.pl

weapon_data.js: process_weapon.pl ia-data/* dual_weapons.dat dual_ccw.dat \
    poison_ccw.dat
	./process_weapon.pl

install: ${WWW_TARGETS} ${BIN_TARGETS}
	cp inf-dice.js inf-dice.css inf-dice.pl ${WWW_TARGETS} ${WWWDIR}
	cp inf-dice-n3 ${BINDIR}

diff:
	for i in ${WWW_TARGETS}; do diff -u ${WWWDIR} $$i; done

update_data:
	wget -m -np -P ia-data/ -nd http://ia-aleph.googlecode.com/hg/ia-aleph/src/main/javascript/data/
	wget -m -np -P ia-data/ -nd http://ia-aleph.googlecode.com/hg/ia-aleph/src/main/javascript/lang/ia-lang_40_en.js
