#  ____   ____ ______ ____    ___
#  || \\ ||    | || | || \\  // \\
#  ||_// ||==    ||   ||_// ((   ))
#  || \\ ||___   ||   || \\  \\_//
#  a personal, minimalistic forth

CC = clang
LD = clang
LDFLAGS =
CFLAGS = -Wall -O3

all: clean sources tools compile link image rre repl kanga finish opt

clean:
	rm -f bin/rre bin/nga bin/embedimage bin/extend bin/unu bin/muri bin/kanga

sources:
	cd source && $(CC) $(CFLAGS) unu.c -o ../bin/unu
	./bin/unu literate/Unu.md >source/unu.c
	./bin/unu literate/Nga.md >source/nga.c
	./bin/unu literate/Muri.md >source/muri.c
	./bin/unu literate/Rx.md >rx.muri
	./bin/unu literate/RetroForth.md >retro.forth

tools:
	cd source && $(CC) $(CFLAGS) unu.c -o ../bin/unu
	cd source && $(CC) $(CFLAGS) nga.c -DSTANDALONE -o ../bin/nga
	cd source && $(CC) $(CFLAGS) muri.c -o ../bin/muri

compile:
	cd source && $(CC) $(CFLAGS) -c nga.c -o nga.o
	cd source && $(CC) $(CFLAGS) -c extend.c -o extend.o
	cd source && $(CC) $(CFLAGS) -c embedimage.c -o embedimage.o
	cd source && $(CC) $(CFLAGS) -c rre.c -o rre.o
	cd source && $(CC) $(CFLAGS) -c repl.c -o repl.o
	cd source && $(CC) $(CFLAGS) -c kanga.c -o kanga.o
	cd source && $(CC) $(CFLAGS) -c cursed-bridge.c -o cursed-bridge.o
	cd source && $(CC) $(CFLAGS) -c bridge.c -o bridge.o
	mv source/*.o bin

link:
	cd bin && $(LD) $(LDFLAGS) nga.o extend.o bridge.o -o extend
	cd bin && $(LD) $(LDFLAGS) embedimage.o bridge.o -o embedimage

repl:
	cd bin && $(CC) $(CFLAGS) repl.o nga.o bridge.o -o repl

kanga:
	cd bin && $(CC) $(CFLAGS) kanga.o nga.o cursed-bridge.o -lcurses -o kanga

image:
	./bin/muri rx.muri
	./bin/extend retro.forth

rre:
	cp ngaImage clean
	./bin/extend source/rre.forth
	./bin/embedimage >source/image.c
	mv clean ngaImage
	cd source && $(CC) $(CFLAGS) -c image.c -o ../bin/image.o
	cd bin && $(CC) $(CFLAGS) rre.o nga.o image.o bridge.o -o rre

finish:
	rm -f bin/*.o

opt:
	cd optional && ../bin/unu literate/Array.md >array.forth
	cd optional && ../bin/unu literate/NS.md >ns.forth
