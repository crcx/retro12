#  ____   ____ ______ ____    ___
#  || \\ ||    | || | || \\  // \\
#  ||_// ||==    ||   ||_// ((   ))
#  || \\ ||___   ||   || \\  \\_//
#  a personal, minimalistic forth

CC = clang
LD = clang
LDFLAGS = -lm
CFLAGS = -Wall -O3

all: clean tools update_sources image interfaces finally test

clean:
	rm -f bin/rre bin/nga bin/embedimage bin/extend bin/unu bin/muri bin/kanga bin/repl bin/tanu

tools:
	cd source && $(CC) $(CFLAGS) unu.c -o ../bin/unu
	cd source && $(CC) $(CFLAGS) muri.c -o ../bin/muri
	cd source && $(CC) $(CFLAGS) tanu.c -o ../bin/tanu
	cd source && $(CC) $(CFLAGS) build.c -o ../bin/build
	cd source && make extend
	cd source && make embedimage

update_sources:
	./bin/unu literate/Unu.md >source/unu.c
	./bin/unu literate/Nga.md >source/nga.c
	./bin/unu literate/Muri.md >source/muri.c
	./bin/tanu source/io/posix-files.forth posix_files >source/io/posix_files.c
	./bin/tanu source/io/posix-args.forth posix_args >source/io/posix_args.c
	./bin/tanu source/io/getc.forth posix_getc >source/io/getc.c
	./bin/tanu source/io/FloatingPoint.forth fpu >source/io/fpu.c
	./bin/embedimage >source/image.c

image:
	./bin/muri literate/Rx.md
	./bin/extend literate/RetroForth.md

interfaces:
	cd source && make rre
	cd source && make repl
	cd source && make kanga

finally:
	rm source/*.o

test:
	./bin/rre test-core.forth
