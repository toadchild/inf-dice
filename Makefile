CFLAGS=-O2

all: stupid_dice

clean:
	rm -f stupid_dice stupid_dice.o

stupid_dice: stupid_dice.o

stupid_dice.o: stupid_dice.c
