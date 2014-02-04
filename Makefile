CFLAGS=-O2
LDFLAGS=
LDLIBS=-lm -lpthread

all: stupid_dice

clean:
	rm -f stupid_dice stupid_dice.o

stupid_dice: stupid_dice.o

stupid_dice.o: stupid_dice.c
