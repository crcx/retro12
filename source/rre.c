/*  ____   ____ ______ ____    ___
    || \\ ||    | || | || \\  // \\
    ||_// ||==    ||   ||_// ((   ))
    || \\ ||___   ||   || \\  \\_//
    a personal, minimalistic forth

    This is `rre`, short for `run retro and exit`. It's the
    basic interface layer for Retro on Linux and macOS.

    `rre` embeds the image file into the binary, so the
    compiled version of this is all you need to have a
    functional system.

    Copyright (c) 2016, 2017 Charles Childers
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>

/* Eventually bridge.c should be compiled separate
   and have a corresponding bridge.h */
#include "bridge.c"

/* Compile image.c and link against the image.o */
extern CELL ngaImageCells;
extern CELL ngaImage[];

void dump_stack() {
  CELL i;
  if (sp == 0)
    return;
  printf("\nStack: ");
  for (i = 1; i <= sp; i++) {
    if (i == sp)
      printf("[ TOS: %d ]", data[i]);
    else
      printf("%d ", data[i]);
  }
  printf("\n");
}


void include_file(char *fname) {
  char source[64000];
  FILE *fp;
  fp = fopen(fname, "r");
  if (fp == NULL)
    return;
  while (!feof(fp))
  {
    read_token(fp, source, 0);
    evaluate(source);
  }
  fclose(fp);
}


int main(int argc, char **argv) {
  int i;
  ngaPrepare();
  for (i = 0; i < ngaImageCells; i++)
    memory[i] = ngaImage[i];
  update_rx();

  include_file(argv[1]);

  if (sp >= 1)
    dump_stack();

  exit(0);
}
