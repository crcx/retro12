#  ____   ____ ______ ____    ___
#  || \\ ||    | || | || \\  // \\
#  ||_// ||==    ||   ||_// ((   ))
#  || \\ ||___   ||   || \\  \\_//
#  a personal, minimalistic forth

CC = clang
LD = clang
LDFLAGS = -lm
CFLAGS = -Wall -O3 -DFPU -DARGV

all: clean sources tools io compile link image rre repl kanga finish test

clean:
	rm -f bin/rre bin/nga bin/embedimage bin/extend bin/unu bin/muri bin/kanga bin/repl

sources:
	cd source && $(CC) $(CFLAGS) unu.c -o ../bin/unu
	./bin/unu literate/Unu.md >source/unu.c
	./bin/unu literate/Nga.md >source/nga.c
	./bin/unu literate/Muri.md >source/muri.c

tools:
	cd source && $(CC) $(CFLAGS) unu.c -o ../bin/unu
	cd source && $(CC) $(CFLAGS) nga.c -DSTANDALONE -o ../bin/nga
	cd source && $(CC) $(CFLAGS) muri.c -o ../bin/muri
	cd source && $(CC) $(CFLAGS) tanu.c -o ../bin/tanu
	cd source && $(CC) $(CFLAGS) build.c -o ../bin/build

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
	cd bin && $(CC) $(CFLAGS) $(LDFLAGS) repl.o nga.o bridge.o -o repl

kanga:
	cd source && ../bin/build kanga
	mv source/kanga bin/

image:
	./bin/muri literate/Rx.md
	./bin/extend literate/RetroForth.md

io:
	./bin/tanu source/io/posix-files.forth posix_files >source/io/posix_files.c
	./bin/tanu source/io/posix-args.forth posix_args >source/io/posix_args.c
	./bin/tanu source/io/getc.forth posix_getc >source/io/getc.c
	./bin/tanu source/io/FloatingPoint.forth fpu >source/io/fpu.c

rre:
	./bin/embedimage >source/image.c
	cd source && ../bin/build rre
	mv source/rre bin/

finish:
	rm -f bin/*.o

test:
	./bin/rre test-core.forth
