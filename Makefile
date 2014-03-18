CFLAGS=-O2
LDFLAGS=
LDLIBS=-lm -lpthread

WWWDIR=/var/www/inf-dice
BINDIR=/usr/local/bin

WWW_TARGETS=hitbar.css hex.png unit_data.js weapon_data.js
BIN_TARGETS=inf-dice

all: ${WWW_TARGETS} ${BIN_TARGETS}

clean:
	rm -f ${WWW_TARGETS} ${BIN_TARGETS} dual_weapons.dat

inf-dice: inf-dice.o

inf-dice.o: inf-dice.c

hitbar.css: hitbar.pl
	./hitbar.pl > hitbar.css

hex.png: hexgrid.pl
	./hexgrid.pl 100 hex.png

dual_weapons.dat: process_unit.pl ia-data/*
	./process_unit.pl

unit_data.js: process_unit.pl ia-data/*
	./process_unit.pl

weapon_data.js: process_weapon.pl ia-data/* dual_weapons.dat
	./process_weapon.pl

install: ${WWW_TARGETS} ${BIN_TARGETS}
	cp inf-dice.js inf-dice.css inf-dice.pl ${WWW_TARGETS} ${WWWDIR}
	cp inf-dice ${BINDIR}

update_data:
	wget -m -np -P ia-data/ -nd http://ia-aleph.googlecode.com/hg/ia-aleph/src/main/javascript/data/
	wget -m -np -P ia-data/ -nd http://ia-aleph.googlecode.com/hg/ia-aleph/src/main/javascript/lang/ia-lang_40_en.js
