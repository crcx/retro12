#  ____   ____ ______ ____    ___
#  || \\ ||    | || | || \\  // \\
#  ||_// ||==    ||   ||_// ((   ))
#  || \\ ||___   ||   || \\  \\_//
#  a personal, minimalistic forth

CC = clang
CFLAGS = -Wall

all: clean sources tools compile link image rre listener finish

clean:
	rm -f bin/*
	touch bin/_

sources:
	cd source && $(CC) $(CFLAGS) unu.c -o ../bin/unu
	./bin/unu literate/Unu.md >source/unu.c
	./bin/unu literate/Nga.md >source/nga.c
	./bin/unu literate/Naje.md >source/naje.c
	./bin/unu literate/Rx.md >rx.naje
	./bin/unu literate/RetroForth.md >retro.forth

tools:
	cd source && $(CC) $(CFLAGS) unu.c -o ../bin/unu
	cd source && $(CC) $(CFLAGS) nga.c -DSTANDALONE -o ../bin/nga
	cd source && $(CC) $(CFLAGS) naje.c -DDEBUG -DALLOW_FORWARD_REFS -DENABLE_MAP -o ../bin/naje

compile:
	cd source && $(CC) $(CFLAGS) -c nga.c -o nga.o
	cd source && $(CC) $(CFLAGS) -c extend.c -o extend.o
	cd source && $(CC) $(CFLAGS) -c embedimage.c -o embedimage.o
	cd source && $(CC) $(CFLAGS) -c rre.c -o rre.o
	mv source/*.o bin

link:
	cd bin && $(CC) nga.o extend.o -o extend
	cd bin && $(CC) embedimage.o -o embedimage

image:
	./bin/naje rx.naje
	./bin/extend retro.forth

rre:
	./bin/embedimage >source/image.c
	cd source && $(CC) $(CFLAGS) -c image.c -o ../bin/image.o
	cd bin && $(CC) $(CFLAGS) rre.o nga.o image.o -o rre

listener:
	cd source/deprecated && $(CC) $(CFLAGS) -c listener.c -o ../../bin/listener.o
	cd bin && $(CC) $(CFLAGS) listener.o nga.o -o listener

finish:
	rm -f bin/*.o
